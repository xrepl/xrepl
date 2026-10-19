from pathlib import Path
import tempfile,subprocess,shutil,hashlib,json,os
root=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl')
art=root/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice02-node-authority-leases/artifacts'
fresh=Path(tempfile.mkdtemp(prefix='cayrn-x02-fresh-',dir='/private/tmp'))
base='apps/cayrn_lfe/'
paths=set(subprocess.check_output(['git','ls-files','--',base],cwd=root,text=True).splitlines())
paths.update(p for p in json.loads((art/'source-baseline.json').read_text())['files'] if p.startswith(base) and (root/p).exists())
manifest={}
for rel in sorted(paths):
 src=root/rel
 assert '_build' not in src.parts and src.suffix!='.beam',rel
 dst=fresh/rel.removeprefix(base);dst.parent.mkdir(parents=True,exist_ok=True)
 shutil.copy2(src,dst)
 manifest[rel]=hashlib.sha256(src.read_bytes()).hexdigest()
(art/'fresh-source-manifest.json').write_text(json.dumps({'directory':str(fresh),'files':manifest,'inherited_build_files':0},indent=2)+'\n')
log=art/'fresh-source-check.log'
with log.open('w') as f:
 f.write('$ make check\nSOURCE '+str(fresh)+'\nNO inherited _build/.beam\n');f.flush()
 run=subprocess.run(['make','check'],cwd=fresh,stdout=f,stderr=subprocess.STDOUT)
 f.write('\nEXIT '+str(run.returncode)+'\n')
print('fresh source check',run.returncode,fresh)
print(log.read_text()[-3500:])
raise SystemExit(run.returncode)
