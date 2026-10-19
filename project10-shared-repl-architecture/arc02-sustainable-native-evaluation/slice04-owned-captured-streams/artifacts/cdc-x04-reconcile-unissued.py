# UNEXECUTED independent committed-candidate reconciliation; pass actual CC return commit.
from pathlib import Path
import json,subprocess,hashlib,sys
X=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');P=X/'.worktrees/planning';S=P/'project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice04-owned-captured-streams';A=S/'artifacts';T=Path('/private/tmp/cdc-x04')
cc_return=sys.argv[1]
c=json.loads((A/'source-candidate.json').read_text());baseline=json.loads((A/'source-baseline.json').read_text());base=c['base'];pin=c['commit'];paths=sorted(c['after'])
def git(repo,*args):return subprocess.check_output(['git',*args],cwd=repo)
def sha(b):return hashlib.sha256(b).hexdigest()
assert base==baseline['source']=='7427d1c8e43183b25012e6870937347c39425606'
assert set(paths)==set(baseline['before']) and len(paths)==12
assert sorted(git(X,'diff','--name-only',base,pin).decode().splitlines())==paths
assert git(X,'rev-parse','HEAD').decode().strip()==pin
for p in paths:
 assert sha((X/p).read_bytes())==c['after'][p]
 assert sha(git(X,'show',pin+':'+p))==c['after'][p]
 assert c['before'][p]==baseline['before'][p]
 if c['before'][p] is None:
  assert subprocess.run(['git','cat-file','-e',base+':'+p],cwd=X,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode!=0
 else:assert sha(git(X,'show',base+':'+p))==c['before'][p]
patch=git(X,'diff','--binary',base,pin);assert patch==(A/'source-candidate.patch').read_bytes();assert sha(patch)==c['patch_sha256']
assert sha((A/'stream-ownership-contract.md').read_bytes())=='976ab5ff3301e1448ba4ae21e973c8636fe83960474f422d00bb962eb46adabc'
assert git(X,'status','--porcelain').decode().strip()=='?? docs/design/'
assert git(X,'diff','--cached','--name-only')==b''
for repo,pin0 in [(X,pin),(P,cc_return)]:
 message=git(repo,'show','-s','--format=%B',pin0).decode()
 for trailer in ['Co-authored-by: Codex <noreply@openai.com>','Co-authored-by: Billo AI <ai-engineering@billo.systems>']:assert trailer in message
ccpaths=git(P,'diff-tree','--no-commit-id','--name-only','-r',cc_return).decode().splitlines()
expected=['artifacts/execution.md','artifacts/intake.log','artifacts/validation.log','artifacts/source-candidate.json','artifacts/source-candidate.patch','artifacts/artifact-inventory.md','closing-report.md','ledger.md']
assert sorted(ccpaths)==sorted(str((S/p).relative_to(P)) for p in expected)
subprocess.run(['git','diff','--check',base,pin],cwd=X,check=True)
T.mkdir(exist_ok=True)
(T/'cdc-source-reconciliation.json').write_text(json.dumps(dict(source=pin,base=base,paths=paths,before_after_and_commit_match=True,patch_sha256=sha(patch),candidate_sha256=sha((A/'source-candidate.json').read_bytes()),cc_planning_return=cc_return,cc_exact_return_paths=ccpaths,original_contract_hash_preserved=True,trailers=True,status_preserved=True),indent=2)+'\n')
print('Exact12 source, before/after committed hashes, binary patch, immutable contract, exact8 CC return and trailers reconcile')
