%% One immutable operation attribution per I/O server, including late writers.
-module(cayrn_lfe_io).
-export([start/2, loop/2]).
-spec start(pid(), binary()) -> pid().
start(Owner, Operation) -> spawn_link(?MODULE, loop, [Owner, Operation]).
-spec loop(pid(), binary()) -> no_return().
loop(Owner, Operation) -> loop(Owner, Operation, false).
loop(Owner, Operation, Closed) ->
    receive
        {seal, Owner} ->
            Owner ! {sealed, self()},
            loop(Owner, Operation, true);
        {io_request, From, Ref, _} when Closed ->
            From ! {io_reply, Ref, {error, terminated}},
            loop(Owner, Operation, Closed);
        {io_request, From, Ref, Request} ->
            case output(Request) of
                {ok, Text} when byte_size(Text) =< 8192 ->
                    Owner ! {capture, From, Ref, Operation, Text};
                {ok, _} -> From ! {io_reply, Ref, {error, emsgsize}};
                {error, Reason} -> From ! {io_reply, Ref, {error, Reason}}
            end,
            loop(Owner, Operation, Closed);
        _ -> loop(Owner, Operation, Closed)
    end.
output({put_chars, Encoding, Text}) -> text(Text, Encoding);
output({put_chars, Text}) -> text(Text, unicode);
output({put_chars, Encoding, Module, Function, Args}) ->
    try text(apply(Module, Function, Args), Encoding)
    catch _:_ -> {error, badarg} end;
output({put_chars, Module, Function, Args}) ->
    output({put_chars, unicode, Module, Function, Args});
output(_) -> {error, enotsup}.
text(Text, Encoding) ->
    try unicode:characters_to_binary(Text, Encoding, utf8) of
        Binary when is_binary(Binary) -> {ok, Binary};
        _ -> {error, badarg}
    catch _:_ -> {error, badarg} end.
