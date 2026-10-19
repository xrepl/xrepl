from pathlib import Path
import subprocess,hashlib,json,tempfile,shutil,os
X=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');C=Path('/Users/oubiwann/lab/oxur/cayrn')
A=Path('/private/tmp/cdc-x03');A.mkdir(exist_ok=True)
S=X/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice03-bounded-result-previews/artifacts'
candidate=json.loads((S/'source-candidate.json').read_text());expected=candidate['after']
def snapshot():return {p:hashlib.sha256((X/p).read_bytes()).hexdigest() for p in expected}
def git(repo,*args):return subprocess.check_output(['git',*args],cwd=repo,text=True).strip()
initial=snapshot();assert initial==expected
pin=git(X,'rev-parse','HEAD');assert pin=='7427d1c8e43183b25012e6870937347c39425606'
assert git(X,'status','--porcelain')=='?? docs/design/'
assert git(C,'rev-parse','HEAD')=='34af63eb9f07a0e019495378045852ad69d00284';assert git(C,'status','--porcelain')==''
env=os.environ.copy()
for name in ['CAYRN_LFE_DIR','XREPL_DIR','XREPL_BIN','CARGO_TARGET_DIR']:env.pop(name,None)
results=[]
def run(label,args,cwd):
 assert snapshot()==initial
 path=A/(label+'.log');assert not path.exists()
 with path.open('w') as f:
  f.write('CDC /root independently executed\nSOURCE '+pin+'\nCWD '+str(cwd)+'\nCOMMAND '+repr(args)+'\n');f.flush()
  p=subprocess.run(args,cwd=cwd,env=env,stdout=f,stderr=subprocess.STDOUT)
  f.write('\nEXIT '+str(p.returncode)+'\n')
 assert snapshot()==initial
 results.append(dict(label=label,args=args,cwd=str(cwd),exit=p.returncode,source=pin,hashes_agree=True))
 (A/'cdc-gate-results.json').write_text(json.dumps(results,indent=2)+'\n');print(label,'exit',p.returncode,flush=True)
 if p.returncode:raise SystemExit(p.returncode)
run('cdc-cayrn-full-01',['make','check','lint-integration','test-xrepl'],C)
# Explicit generated test shadows only; inventory and ignored proof retained for X-TOOL-01.
shadows=[]
for beam in sorted((X/'apps/cayrn_lfe/test').glob('*.beam')):
 rel=str(beam.relative_to(X));assert subprocess.run(['git','check-ignore','-q','--',rel],cwd=X).returncode==0
 shadows.append(dict(path=rel,sha256=hashlib.sha256(beam.read_bytes()).hexdigest(),size=beam.stat().st_size));beam.unlink()
(A/'cdc-generated-shadow-inventory.json').write_text(json.dumps(shadows,indent=2)+'\n')
run('cdc-current-test-precompile-01',['rebar3','as','test','compile'],X/'apps/cayrn_lfe')
run('cdc-root-full-01',['make','test-lfe','build-agent','check-agent','build','lint-rust','test-rust'],X)
fresh=Path(tempfile.mkdtemp(prefix='cayrn-x03-cdc-fresh-',dir='/private/tmp'))
files=git(X,'ls-files','--','apps/cayrn_lfe/').splitlines();manifest={}
for rel in files:
 src=X/rel;assert '_build' not in src.parts and src.suffix!='.beam'
 dest=fresh/rel.removeprefix('apps/cayrn_lfe/');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
 manifest[rel]=hashlib.sha256(src.read_bytes()).hexdigest()
(A/'cdc-fresh-manifest.json').write_text(json.dumps(dict(source=pin,directory=str(fresh),inherited_build_files=0,files=manifest),indent=2)+'\n')
run('cdc-fresh-native-01',['make','check'],fresh)
smoke=Path('/private/tmp/cdc-x02-root-launcher.py').read_text()
smoke=smoke.replace("art=root/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice02-node-authority-leases/artifacts'","art=Path('/private/tmp/cdc-x03')").replace('cayrn-x02-root launch ','cayrn-x03-root launch ').replace('version=3','version=4').replace("grant['version']==3","grant['version']==4").replace("ready['kind']=='ready' and", "ready['kind']=='ready' and ready['version']==4 and").replace("and out['value']==expected,out","and out['value']==expected and out['preview']=={'truncated':False},out")
smoke_path=A/'cdc-root-launcher.py';smoke_path.write_text(smoke)
run('cdc-root-launcher-wrapper-01',['python3',str(smoke_path)],Path('/private/tmp'))
(A/'cdc-verified-source.json').write_text(json.dumps(dict(xrepl=pin,cayrn=git(C,'rev-parse','HEAD'),files=initial,source_status=git(X,'status','--short')),indent=2)+'\n')
print('CDC all current gates complete',pin,flush=True)
