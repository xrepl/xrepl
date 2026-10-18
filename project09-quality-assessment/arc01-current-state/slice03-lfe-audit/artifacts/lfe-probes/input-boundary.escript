#!/usr/bin/env escript
-mode(compile).
main(_) ->
 Root="/Users/oubiwann/lab/lfe/xrepl/xrepl",code:add_pathsa(filelib:wildcard(Root++"/_build/default/lib/*/ebin")),
 lists:foreach(fun(Line) -> io:format("reader ~p -> ~p; public_read -> ~p~n",[Line,lfe_io:read_string(Line),read_line(Line)]) end,["go back\n","take key\n","(go back)\n","((\n"]),halt(0).
read_line(Line)->Old=group_leader(),Fake=spawn(fun()->fixture(Line) end),group_leader(Fake,self()),
 R=try 'xrepl-io':'read-expression'("> ") catch C:E -> {caught,C,E} end,
 group_leader(Old,self()),exit(Fake,kill),R.
fixture(Line)->receive {io_request,From,Ref,{get_line,_,_}}->From!{io_reply,Ref,Line},fixture(eof);
 {io_request,From,Ref,_}->From!{io_reply,Ref,ok},fixture(Line) end.
