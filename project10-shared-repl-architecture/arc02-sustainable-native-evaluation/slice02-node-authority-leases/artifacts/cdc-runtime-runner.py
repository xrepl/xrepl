from pathlib import Path
import subprocess,hashlib,json,tempfile,shutil,os
X=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');C=Path('/Users/oubiwann/lab/oxur/cayrn')
A=X/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice02-node-authority-leases/artifacts'
expected=json.loads((A/'final-source-before-gates.json').read_text())
def snapshot():
 return {p:hashlib.sha256((X/p).read_bytes()).hexdigest() for p in expected}
def git(repo,*args):return subprocess.check_output(['git',*args],cwd=repo,text=True).strip()
initial=snapshot();assert initial==expected
pin=git(X,'rev-parse','HEAD');assert pin!='7228183e2e584e0ab86e03dc6b9454d4b918cc38','Candidate not committed'
assert git(X,'status','--porcelain','--untracked-files=no')=='','Source not clean'
assert git(C,'rev-parse','HEAD')=='3bcbbdb9ec52667b6c75b7f8a5f2260b93d8be44'
assert git(C,'status','--porcelain')==''
env=os.environ.copy()
for name in ['CAYRN_LFE_DIR','XREPL_DIR','XREPL_BIN','CARGO_TARGET_DIR']:env.pop(name,None)
results=[]
def run(label,args,cwd):
 assert snapshot()==initial
 path=A/(label+'.log')
 assert not path.exists(),str(path)+' already exists'
 with path.open('w') as f:
  f.write('CDC /root independently executed\nSOURCE '+pin+'\nCWD '+str(cwd)+'\nCOMMAND '+repr(args)+'\n');f.flush()
  p=subprocess.run(args,cwd=cwd,env=env,stdout=f,stderr=subprocess.STDOUT)
  f.write('\nEXIT '+str(p.returncode)+'\n')
 current=snapshot();assert current==initial
 record=dict(label=label,args=args,cwd=str(cwd),exit=p.returncode,source=pin,hashes_agree=True)
 results.append(record);(A/'cdc-gate-results.json').write_text(json.dumps(results,indent=2)+'\n')
 print(label,'exit',p.returncode,flush=True)
 if p.returncode:raise SystemExit(p.returncode)
run('cdc-cayrn-full-01',['make','check','lint-integration','test-xrepl'],C)
run('cdc-root-full-01',['make','test-lfe','build-agent','check-agent','build','lint-rust','test-rust'],X)
fresh=Path(tempfile.mkdtemp(prefix='cayrn-x02-cdc-fresh-',dir='/private/tmp'))
files=subprocess.check_output(['git','ls-files','--','apps/cayrn_lfe/'],cwd=X,text=True).splitlines();manifest={}
for rel in files:
 src=X/rel;assert '_build' not in src.parts and src.suffix!='.beam',rel
 dest=fresh/rel.removeprefix('apps/cayrn_lfe/');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
 manifest[rel]=hashlib.sha256(src.read_bytes()).hexdigest()
(A/'cdc-fresh-manifest.json').write_text(json.dumps(dict(source=pin,directory=str(fresh),inherited_build_files=0,files=manifest),indent=2)+'\n')
run('cdc-fresh-native-01',['make','check'],fresh)
smoke=Path('/private/tmp/x02-root-launcher.py').read_text().replace("art/'root-launcher-process.log'","art/'cdc-root-launcher-process.log'").replace("art/'root-launcher.log'","art/'cdc-root-launcher.log'")
smoke_path=Path('/private/tmp/cdc-x02-root-launcher.py');smoke_path.write_text(smoke)
run('cdc-root-launcher-wrapper-01',['python3',str(smoke_path)],Path('/private/tmp'))
(A/'cdc-verified-source.json').write_text(json.dumps(dict(xrepl=pin,cayrn=git(C,'rev-parse','HEAD'),files=initial,source_status=git(X,'status','--short')),indent=2)+'\n')
print('CDC all current gates complete',pin,flush=True)
