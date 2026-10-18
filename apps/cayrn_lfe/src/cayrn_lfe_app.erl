-module(cayrn_lfe_app).
-behaviour(application).
-export([start/2, stop/1]).
-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_, _) -> cayrn_lfe_sup:start_link().
-spec stop(term()) -> ok.
stop(_) -> ok.
