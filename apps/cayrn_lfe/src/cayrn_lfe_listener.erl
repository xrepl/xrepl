-module(cayrn_lfe_listener).
-behaviour(gen_server).
-export([start_link/0, init/1, handle_info/2, handle_call/3, handle_cast/2, terminate/2]).
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
-spec init([]) -> {ok, map()} | {stop, term()}.
init([]) ->
    _ = ets:new(cayrn_lfe_contexts, [named_table, public, set, {write_concurrency, true}]),
    {ok, Path} = application:get_env(cayrn_lfe, socket),
    case gen_tcp:listen(0, [binary, {active, false}, {packet, 4},
            {packet_size, 262144}, {ifaddr, {local, Path}}, {backlog, 64}]) of
        {ok, Socket} ->
            ok = file:change_mode(Path, 8#600),
            self() ! accept,
            {ok, #{socket => Socket, path => Path}};
        Error -> {stop, Error}
    end.
-spec handle_info(term(), map()) -> {noreply, map()}.
handle_info(accept, #{socket := Listener} = State) ->
    case gen_tcp:accept(Listener, 100) of
        {ok, Socket} ->
            case supervisor:count_children(cayrn_lfe_sup) of
                Counts ->
                    case proplists:get_value(active, Counts) =< 64 of
                        true ->
                            case cayrn_lfe_sup:context(Socket) of
                                {ok, Pid} ->
                                    ok = gen_tcp:controlling_process(Socket, Pid),
                                    Pid ! activate;
                                _ -> gen_tcp:close(Socket)
                            end;
                        false -> gen_tcp:close(Socket)
                    end
            end;
        {error, timeout} -> ok;
        {error, closed} -> exit(listener_closed);
        {error, Reason} -> exit(Reason)
    end,
    self() ! accept,
    {noreply, State};
handle_info(_, State) -> {noreply, State}.
-spec handle_call(term(), gen_server:from(), map()) -> {reply, term(), map()}.
handle_call(_, _, State) -> {reply, {error, unsupported}, State}.
-spec handle_cast(term(), map()) -> {noreply, map()}.
handle_cast(_, State) -> {noreply, State}.
-spec terminate(term(), map()) -> ok.
terminate(_, #{socket := Socket, path := Path}) ->
    gen_tcp:close(Socket),
    _ = file:delete(Path),
    ok.
