%% A connection owns one live execution context; client attachments end at Rust.
-module(cayrn_lfe_context).
-behaviour(gen_server).
-export([start_link/1, init/1, handle_info/2, handle_call/3, handle_cast/2, terminate/2]).
-spec start_link(port()) -> {ok, pid()} | {error, term()}.
start_link(Socket) -> gen_server:start_link(?MODULE, Socket, []).
-spec init(port()) -> {ok, map(), timeout()}.
init(Socket) ->
    process_flag(trap_exit, true),
    {ok, #{socket => Socket, identity => undefined, env => 'cayrn-lfe-eval':new(),
        active => undefined, seen => #{}, ios => [], pending => #{}, seq => 0, closing => undefined}, 5000}.
-spec handle_info(term(), map()) -> {noreply, map()} | {noreply, map(), timeout()} | {stop, term(), map()}.
handle_info(activate, #{socket := Socket} = State) ->
    ok = inet:setopts(Socket, [{active, once}]),
    {noreply, State, 5000};
handle_info({tcp, Socket, Binary}, #{socket := Socket} = State) ->
    try command(json:decode(Binary), State) of
        {continue, Next} ->
            ok = inet:setopts(Socket, [{active, once}]), {noreply, Next};
        {stop, Next} -> {stop, normal, Next}
    catch _:_ -> {stop, invalid_agent_command, State} end;
handle_info({capture, From, Ref, Op, Text}, State) ->
    Pending = maps:get(pending, State),
    case map_size(Pending) < 64 of
        true ->
            N = maps:get(seq, State) + 1,
            Position = integer_to_binary(N),
            ok = send(State, #{kind => output, operation => Op, position => Position, text => Text}),
            {noreply, State#{seq => N, pending => Pending#{Position => {From, Ref}}}};
        false ->
            From ! {io_reply, Ref, {error, enobufs}},
            {stop, capture_overflow, State}
    end;
handle_info({evaluated, Pid, Op, Status, Text, Env}, #{active := {Pid, Mon, Op}} = State) ->
    erlang:demonitor(Mon, [flush]),
    true = byte_size(Text) =< 8192,
    ok = send(State, #{kind => outcome, operation => Op, phase => Status, value => Text}),
    transition(progress(State#{active => undefined, env => Env}));
handle_info({'DOWN', Mon, process, Pid, _Reason}, #{active := {Pid, Mon, Op}, closing := Mode} = State)
        when Mode =:= close; Mode =:= cancel ->
    ok = send(State, #{kind => outcome, operation => Op, phase => cancelled,
        value => <<"native evaluator terminated; environment discarded">>}),
    transition(progress(State#{active => undefined}));
handle_info({'DOWN', Mon, process, Pid, Reason}, #{active := {Pid, Mon, _}} = State) ->
    {stop, {evaluator_lost, Reason}, State};
handle_info({sealed, Io}, #{waiting := Waiting} = State) ->
    transition(progress(State#{waiting => lists:delete(Io, Waiting)}));
handle_info(close_timeout, #{closing := Mode} = State) when Mode =/= undefined ->
    ok = send(State, #{kind => lost, reason => <<"native close/interrupt incomplete: producer or capture barrier timed out">>}),
    {stop, normal, State};
handle_info({tcp_closed, _}, State) -> {stop, normal, State};
handle_info({tcp_error, _, Reason}, State) -> {stop, Reason, State};
handle_info(timeout, #{identity := undefined} = State) -> {stop, handshake_timeout, State};
handle_info({'EXIT', _, Reason}, State) -> {stop, {io_lost, Reason}, State};
handle_info(_, State) -> {noreply, State}.
command(#{<<"kind">> := <<"hello">>, <<"version">> := 1,
          <<"session">> := Sid, <<"generation">> := Gen, <<"authority">> := Authority},
        #{identity := undefined} = State) ->
    true = valid_id(Sid) andalso valid_id(Gen) andalso valid_id(Authority),
    true = ets:info(cayrn_lfe_contexts, size) < 4096,
    true = ets:insert_new(cayrn_lfe_contexts, {Sid, Gen, Authority}),
    ok = send(State, #{kind => ready, version => 1, backend => <<"lfe">>, interrupt => <<"session_destructive">>, close_barrier => true}),
    {continue, State#{identity => {Sid, Gen, Authority}}};
command(#{<<"kind">> := <<"dispatch">>, <<"operation">> := Op,
          <<"source">> := Source, <<"generation">> := Gen, <<"authority">> := Authority},
        #{identity := {_, Gen, Authority}, active := undefined, seen := Seen, closing := undefined} = State)
        when is_binary(Source), byte_size(Source) =< 8192, map_size(Seen) < 256 ->
    true = valid_id(Op),
    false = maps:is_key(Op, Seen),
    Owner = self(),
    Io = cayrn_lfe_io:start(Owner, Op),
    Env = maps:get(env, State),
    {Pid, Mon} = spawn_monitor(fun() ->
        receive evaluate ->
            {Status, Value, Next} = 'cayrn-lfe-eval':run(Source, Env),
            Phase = case Status of ok -> succeeded; error -> failed end,
            Owner ! {evaluated, self(), Op, Phase, Value, Next}
        end
    end),
    true = group_leader(Io, Pid),
    Pid ! evaluate,
    {continue, State#{active => {Pid, Mon, Op}, seen => Seen#{Op => true},
        ios => [Io | maps:get(ios, State)]}};
command(#{<<"kind">> := <<"ack">>, <<"position">> := Position}, State) ->
    {{From, Ref}, Pending} = maps:take(Position, maps:get(pending, State)),
    From ! {io_reply, Ref, ok},
    progress(State#{pending => Pending});
command(#{<<"kind">> := <<"close">>}, #{closing := undefined} = State) ->
    begin_stop(close, State);
command(#{<<"kind">> := <<"close">>}, State) -> {continue, State};
command(#{<<"kind">> := <<"cancel">>, <<"operation">> := Op},
        #{active := {_, _, Op}, closing := undefined} = State) -> begin_stop(cancel, State);
command(#{<<"kind">> := <<"cancel">>, <<"operation">> := Op},
        #{active := undefined, seen := Seen, closing := undefined} = State) ->
    case maps:is_key(Op, Seen) of
        true -> {continue, State};
        false ->
            ok = send(State, #{kind => lost, reason => <<"interrupt won before native dispatch; context retired">>}),
            {stop, State}
    end;
command(#{<<"kind">> := <<"cancel">>}, State) -> {continue, State};
command(#{<<"kind">> := <<"stop">>}, State) -> {stop, State};
command(_, _) -> error(invalid_agent_command).
begin_stop(Mode, State) ->
    _ = erlang:send_after(5000, self(), close_timeout),
    case maps:get(active, State) of
        {Pid, _, _} -> exit(Pid, kill);
        undefined -> ok
    end,
    progress(State#{closing => Mode}).
progress(#{closing := cancel, active := undefined} = State) ->
    ok = send(State, #{kind => lost, reason => <<"session-destructive interruption ended native context; capture tail may be uncertain">>}),
    {stop, State};
progress(#{closing := close, active := undefined} = State) ->
    case maps:find(waiting, State) of
        error ->
            Io = maps:get(ios, State),
            lists:foreach(fun(Pid) -> Pid ! {seal, self()} end, Io),
            progress(State#{waiting => Io});
        {ok, []} ->
            case map_size(maps:get(pending, State)) of
                0 -> ok = send(State, #{kind => closed}), {stop, State};
                _ -> {continue, State}
            end;
        _ -> {continue, State}
    end;
progress(State) -> {continue, State}.
transition({continue, State}) -> {noreply, State};
transition({stop, State}) -> {stop, normal, State}.
valid_id(Id) when is_binary(Id), byte_size(Id) > 0, byte_size(Id) =< 128 ->
    re:run(Id, <<"^[A-Za-z0-9_-]+$">>, [{capture, none}]) =:= match;
valid_id(_) -> false.
send(#{socket := Socket}, Data) -> gen_tcp:send(Socket, json:encode(Data)).
-spec handle_call(term(), gen_server:from(), map()) -> {reply, term(), map()}.
handle_call(_, _, State) -> {reply, {error, unsupported}, State}.
-spec handle_cast(term(), map()) -> {noreply, map()}.
handle_cast(_, State) -> {noreply, State}.
-spec terminate(term(), map()) -> ok.
terminate(_, State) ->
    case maps:get(active, State) of
        {Pid, _, _} -> exit(Pid, kill);
        undefined -> ok
    end,
    lists:foreach(fun(Pid) -> exit(Pid, kill) end, maps:get(ios, State)),
    gen_tcp:close(maps:get(socket, State)),
    ok.
