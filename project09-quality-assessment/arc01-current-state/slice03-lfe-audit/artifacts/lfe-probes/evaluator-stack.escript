#!/usr/bin/env escript
-mode(compile).
main(_) ->
 Root="/Users/oubiwann/lab/lfe/xrepl/xrepl",code:add_pathsa(filelib:wildcard(Root++"/_build/default/lib/*/ebin")++filelib:wildcard(Root++"/_build/default/checkouts/*/ebin")),
 application:load(xrepl),lists:foreach(fun({K,V})->application:set_env(xrepl,K,V) end,[{history_enabled,false},{history_file,"/private/tmp/xrepl-p09-neutral-probe/history"},{network_enabled,false},{tcp_enabled,false},{unix_enabled,false}]),
 {ok,_}=application:ensure_all_started(xrepl),{ok,S}='xrepl-session-manager':create(),
 Name='xrepl-session':'process-name'(S),Eval=element(5,sys:get_state(Name)),
 io:format("eval_count=0 ~p~n",[process_info(Eval,stack_size)]),
 lists:foreach(fun(N)->lists:foreach(fun(_)->{ok,3}='xrepl-session':eval(S,"(+ 1 2)") end,lists:seq(1,100)),io:format("eval_count=~p ~p~n",[N*100,process_info(Eval,stack_size)]) end,lists:seq(1,5)),
 'xrepl-session-manager':destroy(S),halt(0).
