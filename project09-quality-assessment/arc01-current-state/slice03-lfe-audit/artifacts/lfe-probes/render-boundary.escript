#!/usr/bin/env escript
-mode(compile).
main(_) ->
 Root="/Users/oubiwann/lab/lfe/xrepl/xrepl",code:add_pathsa(filelib:wildcard(Root++"/_build/default/lib/*/ebin")++filelib:wildcard(Root++"/_build/default/checkouts/*/ebin")),
 File="/private/tmp/xrepl-p09-neutral-render.bin",ok=file:write_file(File,<<"NEUTRAL_BYTES">>),
 Old=group_leader(),Sink=spawn(fun sink/0),group_leader(Sink,self()),
 Direct=catch 'xrepl-term-graphics':'render-file'(File,#{protocol=>iterm2}),
 Wrapper=try 'xrepl-client-shell-fns':'render-image'(File,#{protocol=>iterm2}) catch C:R->{caught,C,R} end,
 group_leader(Old,self()),exit(Sink,kill),file:delete(File),
 io:format("resolved_renderer=~p~npublic_render_wrapper=~p~n",[Direct,Wrapper]),
 {module,xrepl}=code:ensure_loaded(xrepl),
 io:format("remote_module_report_for_loaded_xrepl=~p~n",['xrepl-shell-fns':m([xrepl])]),halt(0).
sink()->receive {io_request,From,Ref,_}->From!{io_reply,Ref,ok},sink() end.
