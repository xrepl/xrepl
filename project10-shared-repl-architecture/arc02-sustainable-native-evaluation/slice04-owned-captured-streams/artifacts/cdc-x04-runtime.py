# UNEXECUTED X04 current module/export probe; run only after source freeze/build handoff.
from pathlib import Path
import subprocess,json,hashlib,re
r=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');component=r/'apps/cayrn_lfe';mods=[]
for kind in ['src','test']:
 for p in sorted((component/kind).glob('*.lfe')):
  t=p.read_text();header=t.split('\n\n',1)[0]
  # Header comment can be separated; locate the explicit module form first.
  start=t.index('(defmodule ');header=t[start:].split('\n\n',1)[0]
  name=re.search(r'\(defmodule\s+([^\s()]+)',header).group(1)
  exports=[(m,int(n)) for m,n in re.findall(r'\(([A-Za-z_][A-Za-z0-9_?-]*)\s+(\d+)\)',header)]
  mods.append((name,kind,exports))
atoms='['+','.join("'"+m+"'" for m,_,_ in mods)+']'
expr='Data=lists:map(fun(M) -> #{module=>atom_to_binary(M),path=>list_to_binary(code:which(M)),exports=>[[atom_to_binary(F),A] || {F,A} <- M:module_info(exports)]} end,'+atoms+'),io:format("~ts~n",[json:encode(Data)]), true=lists:member({module,cayrn_lfe_preview_tests},cayrn_lfe_io_tests:native_agent_companions_test_()),true=lists:member({module,cayrn_lfe_stream_tests},cayrn_lfe_io_tests:native_agent_companions_test_()),true=lists:member({module,cayrn_lfe_ownership_tests},cayrn_lfe_io_tests:native_agent_companions_test_()),{ok,<<"42">>,false,_}=\'cayrn-lfe-eval\':run(<<"42">>,\'cayrn-lfe-eval\':new()),halt().'
paths=sorted((component/'_build/test/lib').glob('*/ebin'))+sorted((component/'_build/test/lib').glob('cayrn_lfe/test'))
p=subprocess.run(['erl','+S','2:2','-noshell','-pa',*[str(x) for x in paths],'-eval',expr],capture_output=True,text=True)
print('ARGV isolated erl code:which/exports + actual companion/eval4tuple assertions',flush=True);print(p.stdout,flush=True);print(p.stderr,flush=True);assert p.returncode==0
rows=json.loads(p.stdout)
for row,(name,kind,declared) in zip(rows,mods):
 assert row['module']==name
 actual={tuple(x) for x in row['exports']};allowed={('__info__',1),('module_info',0),('module_info',1),('LFE-EXPAND-EXPORTED-MACRO',3)}
 if kind=='test':allowed.add(('test',0))
 assert actual-set(declared)<=allowed,(name,actual-set(declared))
 assert set(declared)<=actual,(name,set(declared)-actual)
 print('DECLARED/ACTUAL EXPORTS',name,'match; classified generated',sorted(actual-set(declared)),flush=True)
# Inventory regenerated ignored source test BEAMs only; do not remove current files.
rows=[]
for path in sorted((component/'test').glob('*.beam')):
 rows.append({'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
print('FINAL GENERATED SOURCE TEST BEAM IDENTITIES '+json.dumps(rows,indent=2),flush=True)
print('All current declared exports and current preview/stream/ownership companions/evaluator seam match; production='+str(sum(kind=='src' for _,kind,_ in mods))+' test='+str(sum(kind=='test' for _,kind,_ in mods)),flush=True)
