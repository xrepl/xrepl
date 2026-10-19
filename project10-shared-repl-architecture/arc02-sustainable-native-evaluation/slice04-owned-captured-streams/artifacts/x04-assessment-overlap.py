from pathlib import Path
import re,subprocess,json
repo=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');base=repo/'.worktrees/planning/project09-quality-assessment/arc01-current-state'
reports=['slice03-lfe-audit/artifacts/2026.10.17-audit-results-lfe.md','slice04-rust-audit-and-synthesis/artifacts/2026.10.17-audit-results-rust.md','slice04-rust-audit-and-synthesis/artifacts/2026.10.17-shared-tooling.md']
raw=set();paths=set();ids=[]
for report in reports:
 text=(base/report).read_text()
 for section in re.finditer(r'^#{2,3} ((?:LFE|RUST|TOOLS)-\d{3})[^\n]*\n(?P<body>.*?)(?=^#{2,3} |\Z)',text,re.M|re.S):
  ids.append(section.group(1));location=re.search(r'(?:\*\*Location:\*\*|Location:)(.*?)(?:\n\n)',section.group('body'),re.S)
  if location is None:continue
  for token in re.findall(r'`([^`]+)`',location.group(1)):
   raw.add(re.sub(r':\d.*$','',token));m=re.fullmatch(r'(.+):\d[\d,–—-]*',token)
   if m:paths.add(m.group(1))
start='f261152fc150a1addf3286a97b6a1a0324a42869';end='7427d1c8e43183b25012e6870937347c39425606'
changed=set(subprocess.check_output(['git','diff','--name-only',start,end],cwd=repo,text=True).splitlines())
assert len(ids)==len(set(ids))==27;assert len(raw)==42;assert len(paths)==41;assert len(changed)==22;assert not paths&changed
expected={f'LFE-{n:03}' for n in range(1,22)}|{f'RUST-{n:03}' for n in range(1,5)}|{f'TOOLS-{n:03}' for n in range(1,3)};assert set(ids)==expected
result=dict(assessment='b865b3137e841269f9218d978817cc243e6b9278',arc02_base=start,arc02_end=end,ids=ids,original_raw_location_tokens=len(raw),excluded_nonpaths=sorted(raw-paths),actual_paths=sorted(paths),changed_paths=sorted(changed),intersection=sorted(paths&changed),limits='Historical assessment-location extraction, not new semantic audit or sibling term history/repair acceptance. Final X04 delta recheck required.')
Path('/private/tmp/x04-assessment-overlap.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
