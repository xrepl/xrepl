#!/usr/bin/env escript
-mode(compile).
main(_) ->
 Root="/Users/oubiwann/lab/lfe/xrepl/xrepl",
 code:add_pathsa(filelib:wildcard(Root++"/_build/default/lib/*/ebin")++filelib:wildcard(Root++"/_build/default/checkouts/*/ebin")),
 application:load(xrepl),
 lists:foreach(fun({K,V})->application:set_env(xrepl,K,V) end,[{history_enabled,false},{history_file,"/private/tmp/xrepl-p09-neutral-probe/history"},{network_enabled,false},{tcp_enabled,false},{unix_enabled,false}]),
 {ok,_}=application:ensure_all_started(xrepl),
 Files=[{"manifest.lfe",<<"(story (entry start) (assets (images-dir \"assets/images\")))">>},
 {"nodes/start.lfe",<<"(node (id start) (type scene) (body \"Start.\") (on-enter (set undeclared true)) (choices (choice (cmd \"back\") (to finish))))">>},
 {"nodes/finish.lfe",<<"(node (id finish) (type ending) (body \"Finish.\"))">>}],
 {ok,{_,Bin}}=zip:create("neutral.xsf",Files,[memory]),
 {ok,Bundle}='xs-bundle':load(Bin),
 {ok,State,Opening}='xs-shell':start(Bin),
 io:format("neutral_opening=~p undeclared_flag_accepted=~p~n",[Opening,'xs-world':flag('xs-shell':save(State),undeclared)]),
 io:format("string_go_back=~p~n",[brief('xs-shell':eval("go back",State,#{}))]),
 io:format("form_go_back=~p~n",[brief(catch 'xs-shell':eval([go,back],State,#{}))]),
 io:format("bare_atom_back=~p~n",[brief(catch 'xs-shell':eval(back,State,#{}))]),
 W='xs-world':new('xs-bundle':manifest(Bundle)),
 io:format("unicode_codepoint_render=~p~n",[brief(catch 'xs-engine':'render-element'([8212],W))]),
 io:format("malformed_and_condition=~p~n",[brief(catch 'xs-world':'eval-cond'(['and'|bad_tail],W))]),
 {ok,S}='xrepl-session-manager':create(),
 'xrepl-store':'set-metadata'(S,#{'xs-save'=>'xs-shell':save(State)}),
 'xs-shell':eval("go back",State,#{'session-id'=>S}),
 io:format("done_save_disposition=~p~n",['xrepl-store':'get-metadata'(S)]),
 io:format("public_get_bindings=~p~n",[brief(catch 'xrepl-env':'get-bindings'('xrepl-session':'get-env'(S)))]),
 {ok,F}='xrepl-session-manager':create(#{name=>"face"}),
 io:format("hex_name_switch=~p normal_id_attach=~p~n",['xrepl-session-manager':switch("face"),'xrepl-session-manager':attach(F)]),
 'xrepl-session-manager':destroy(S),'xrepl-session-manager':destroy(F), halt(0).
brief({'EXIT',{Reason,[{Mod,Fn,Args,_}|_]}}) when is_list(Args)->{exit,Reason,{Mod,Fn,length(Args)}};
brief({'EXIT',{Reason,[{Mod,Fn,Arity,_}|_]}})->{exit,Reason,{Mod,Fn,Arity}};
brief({ok,{formatted,Text},_})->{ok,Text};
brief({switch_shell,_,_,_}=X)->X;
brief(X)->X.
