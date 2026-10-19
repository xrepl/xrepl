from pathlib import Path
import json,subprocess,hashlib,re
X=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');P=X/'.worktrees/planning';S=P/'project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice03-bounded-result-previews';T=Path('/private/tmp/cdc-x03');A=S/'artifacts'
c=json.loads((A/'source-candidate.json').read_text());base=c['base'];pin=c['commit'];paths=sorted(c['after'])
def git(repo,*args):return subprocess.check_output(['git',*args],cwd=repo)
def sha(b):return hashlib.sha256(b).hexdigest()
assert len(paths)==15
changed=git(X,'diff','--name-only',base,pin).decode().splitlines();assert sorted(changed)==paths
for p in paths:
 assert sha((X/p).read_bytes())==c['after'][p]
 assert sha(git(X,'show',pin+':'+p))==c['after'][p]
 old=c['before'][p]
 if old is None:assert subprocess.run(['git','cat-file','-e',base+':'+p],cwd=X,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode!=0
 else:assert sha(git(X,'show',base+':'+p))==old
patch=git(X,'diff','--binary',base,pin);assert patch==(A/'source-candidate.patch').read_bytes();assert sha(patch)==c['patch_sha256']
assert sha((A/'preview-contract.md').read_bytes())==c['preview_contract_sha256']
assert git(X,'status','--porcelain').decode().strip()=='?? docs/design/'
assert git(X,'diff','--cached','--name-only')==b''
for repo,pin0 in [(X,pin),(P,'47b4b45986b96cdfa9a6c712a3530ae1ba5765fe')]:
 message=git(repo,'show','-s','--format=%B',pin0).decode()
 for trailer in ['Co-authored-by: Codex <noreply@openai.com>','Co-authored-by: Billo AI <ai-engineering@billo.systems>']:assert trailer in message
ccpaths=git(P,'diff-tree','--no-commit-id','--name-only','-r','47b4b45986b96cdfa9a6c712a3530ae1ba5765fe').decode().splitlines()
expected=['artifacts/execution.md','artifacts/intake.log','artifacts/validation.log','artifacts/source-candidate.json','artifacts/source-candidate.patch','artifacts/artifact-inventory.md','closing-report.md','ledger.md']
assert sorted(ccpaths)==sorted(str((S/p).relative_to(P)) for p in expected)
for rel in ['apps/cayrn_lfe/src/cayrn_lfe_authority.lfe','apps/cayrn_lfe/src/cayrn_lfe_connection.lfe']:
 before=git(X,'show',base+':'+rel).replace(b'"version") 3',b'"version") 4').replace(b"'version 3",b"'version 4")
 assert before==(X/rel).read_bytes(),rel
subprocess.run(['git','diff','--check',base,pin],cwd=X,check=True)
(T/'cdc-source-reconciliation.json').write_text(json.dumps(dict(source=pin,base=base,paths=paths,before_after_and_commit_match=True,patch_sha256=sha(patch),candidate_sha256=sha((A/'source-candidate.json').read_bytes()),cc_planning_return='47b4b45986b96cdfa9a6c712a3530ae1ba5765fe',cc_exact_return_paths=ccpaths,restricted_positive_version_only=True,trailers=True,status_preserved=True),indent=2)+'\n')
print('Exact15 source, before/after committed hashes, binary patch, contract, exact8 return, restricted production versions and trailers reconcile')
