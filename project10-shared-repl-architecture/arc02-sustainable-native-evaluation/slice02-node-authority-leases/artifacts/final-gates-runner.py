from pathlib import Path
import subprocess,json,hashlib,os
r=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');a=r/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice02-node-authority-leases/artifacts'
pins=json.loads((a/'final-source-before-gates.json').read_text());env=os.environ.copy()
for k in ['CAYRN_LFE_DIR','XREPL_DIR','XREPL_BIN','CARGO_TARGET_DIR']:env.pop(k,None)
def hashes():return {p:hashlib.sha256((r/p).read_bytes()).hexdigest() for p in pins}
jobs=[('cayrn-full-final-01',['make','check','lint-integration','test-xrepl'],Path('/Users/oubiwann/lab/oxur/cayrn')),('root-final-test-precompile',['rebar3','as','test','compile'],r),('root-full-final-01',['make','test-lfe','build-agent','check-agent','build','lint-rust','test-rust'],r),('root-launcher-wrapper-final',['python3','/private/tmp/x02-root-launcher.py'],Path('/private/tmp'))]
results=[]
for label,cmd,cwd in jobs:
 assert hashes()==pins,('source changed before',label)
 log=a/(label+'.log');assert not log.exists(),log
 with log.open('w') as f:
  f.write('$ '+' '.join(cmd)+'\nCWD '+str(cwd)+'\nOverrides unset: CAYRN_LFE_DIR XREPL_DIR XREPL_BIN CARGO_TARGET_DIR\n');f.flush()
  run=subprocess.run(cmd,cwd=cwd,env=env,stdout=f,stderr=subprocess.STDOUT)
  f.write('\nEXIT '+str(run.returncode)+'\n')
 assert hashes()==pins,('source changed during',label)
 results.append({'label':label,'command':cmd,'cwd':str(cwd),'exit':run.returncode,'all16_source_hashes_agree':True})
 (a/'final-gate-results.json').write_text(json.dumps(results,indent=2)+'\n')
 print(label,'EXIT',run.returncode,flush=True)
 if run.returncode:
  print(log.read_text()[-10000:],flush=True)
  raise SystemExit(run.returncode)
print('All sequential full current-byte gates passed',flush=True)
