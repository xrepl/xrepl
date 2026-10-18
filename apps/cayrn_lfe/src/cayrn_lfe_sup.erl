-module(cayrn_lfe_sup).
-behaviour(supervisor).
-export([start_link/0, init/1, context/1]).
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).
-spec context(port()) -> supervisor:startchild_ret().
context(Socket) ->
    supervisor:start_child(?MODULE, #{id => make_ref(),
        start => {cayrn_lfe_context, start_link, [Socket]},
        restart => temporary, shutdown => 2000}).
-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    {ok, {#{strategy => one_for_all, intensity => 3, period => 10},
        [#{id => cayrn_lfe_listener, start => {cayrn_lfe_listener, start_link, []},
           restart => permanent, shutdown => 2000}]}}.
