-module(cayrn_lfe_io_tests).
-include_lib("eunit/include/eunit.hrl").

capture_requires_owner_ack_test() ->
    Io=cayrn_lfe_io:start(self(), <<"operation">>),
    Ref=make_ref(),
    try
        Io ! {io_request, self(), Ref, {put_chars, unicode, <<"hello">>}},
        receive {capture, From, Ref, <<"operation">>, <<"hello">>} -> ?assertEqual(self(), From)
        after 1000 -> error(missing_capture) end,
        receive {io_reply, Ref, _} -> error(false_native_ack)
        after 20 -> ok end
    after unlink(Io), exit(Io, kill) end.

seal_orders_prior_capture_and_rejects_late_writes_test() ->
    Io=cayrn_lfe_io:start(self(), <<"origin">>),
    Ref=make_ref(),
    try
        Io ! {io_request, self(), Ref, {put_chars, unicode, <<"before">>}},
        Io ! {seal, self()},
        receive First -> ?assertMatch({capture, _, Ref, <<"origin">>, <<"before">>}, First)
        after 1000 -> error(missing_capture) end,
        receive Second -> ?assertEqual({sealed, Io}, Second)
        after 1000 -> error(missing_seal) end,
        Later=make_ref(),
        Io ! {io_request, self(), Later, {put_chars, unicode, <<"after">>}},
        receive {io_reply, Later, Reply} -> ?assertEqual({error, terminated}, Reply)
        after 1000 -> error(missing_late_rejection) end
    after unlink(Io), exit(Io, kill) end.
