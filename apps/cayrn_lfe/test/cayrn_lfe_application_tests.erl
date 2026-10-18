%% Isolate the startup oracle from services started by the legacy test suite.
-module(cayrn_lfe_application_tests).
-include_lib("eunit/include/eunit.hrl").
-include_lib("kernel/include/file.hrl").

independent_application_start_test_() ->
    {timeout, 30, fun independent_application_start/0}.

independent_application_start() ->
    Dir = filename:join("/private/tmp", "cayrn-app-" ++ os:getpid() ++ "-" ++
        integer_to_list(erlang:unique_integer([positive, monotonic]))),
    ok = file:make_dir(Dir),
    ok = file:change_mode(Dir, 8#700),
    Socket = filename:join(Dir, "agent socket.sock"),
    try
        %% Standard I/O control requires neither distribution nor a live user node.
        {ok, Peer, _Node} = peer:start_link(#{connection => standard_io,
            args => ["-pa" | code:get_path()]}),
        try
            ok = peer:call(Peer, application, load, [cayrn_lfe]),
            ok = peer:call(Peer, application, set_env, [cayrn_lfe, socket, Socket]),
            {ok, _} = peer:call(Peer, application, ensure_all_started, [cayrn_lfe]),
            Running = [App || {App, _, _} <-
                peer:call(Peer, application, which_applications, [])],
            ?assert(lists:member(cayrn_lfe, Running)),
            ?assert(lists:member(lfe, Running)),
            lists:foreach(fun(App) -> ?assertNot(lists:member(App, Running)) end,
                [xrepl, ranch, xrepl_protocol, xrepl_term]),
            {ok, Info} = file:read_file_info(Socket),
            ?assertEqual(other, Info#file_info.type),
            ?assertEqual(8#600, Info#file_info.mode band 8#777)
        after
            peer:stop(Peer)
        end
    after
        file:delete(Socket),
        file:del_dir(Dir)
    end.
