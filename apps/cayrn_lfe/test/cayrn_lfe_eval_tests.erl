-module(cayrn_lfe_eval_tests).
-include_lib("eunit/include/eunit.hrl").

persistent_bindings_test() ->
    Env='cayrn-lfe-eval':new(),
    {ok, <<"41">>, Next}='cayrn-lfe-eval':run(<<"(set x 41)">>, Env),
    {ok, <<"42">>, _}='cayrn-lfe-eval':run(<<"(+ x 1)">>, Next).

errors_preserve_committed_environment_test() ->
    {ok, _, Env}='cayrn-lfe-eval':run(<<"(set x 41)">>, 'cayrn-lfe-eval':new()),
    {error, _, Env}='cayrn-lfe-eval':run(<<"(/ 1 0)">>, Env),
    {error, _, Env}='cayrn-lfe-eval':run(<<"(">>, Env),
    {ok, <<"41">>, _}='cayrn-lfe-eval':run(<<"x">>, Env).

functions_and_macro_context_test() ->
    {ok, _, Env}='cayrn-lfe-eval':run(<<"(defun inc (x) (+ x 1))">>, 'cayrn-lfe-eval':new()),
    {ok, <<"42">>, _}='cayrn-lfe-eval':run(<<"(inc 41)">>, Env).

ordinary_error_atom_is_a_value_test() ->
    {ok, <<"error">>, _}='cayrn-lfe-eval':run(<<"'error">>, 'cayrn-lfe-eval':new()).
