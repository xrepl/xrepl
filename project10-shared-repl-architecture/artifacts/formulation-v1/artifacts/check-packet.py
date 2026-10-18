#!/usr/bin/env python3
"""Check packet links and pinned selected-source bytes; no runtime validation."""
import hashlib
import json
from pathlib import Path
import re
import sys

packet = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
planned = Path('/Users/oubiwann/lab/lfe/xrepl/xrepl/.worktrees/planning/project10-shared-repl-architecture')
errors = []
links = 0
markdown = list(packet.rglob('*.md'))
for file in markdown:
    text = file.read_text()
    for number, line in enumerate(text.splitlines(), 1):
        if line.rstrip() != line:
            errors.append(f'{file}:{number}: trailing whitespace')
    if not text.endswith('\n'):
        errors.append(f'{file}: missing final newline')
    if text.count('```') % 2:
        errors.append(f'{file}: unmatched fenced block')
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', text):
        if target.startswith(('http:', 'https:', '#')):
            continue
        target = target.split('#', 1)[0]
        logical = (planned / file.relative_to(packet)).parent / target
        resolved = logical.resolve()
        if resolved.is_relative_to(planned):
            resolved = packet / resolved.relative_to(planned)
        links += 1
        if not resolved.exists():
            errors.append(f'{file}: missing local link {target}')
manifest = json.loads((packet / 'artifacts/05-baseline.json').read_text())
source_files = 0
for repo in manifest['repositories'].values():
    for item in repo['selected_files']:
        file = Path(repo['path']) / item['path']
        source_files += 1
        if not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != item['sha256']:
            errors.append(f'baseline bytes changed: {file}')
reference = manifest['operator_lfe_reference']
if hashlib.sha256(Path(reference['path']).read_bytes()).hexdigest() != reference['sha256']:
    errors.append('Operator LFE reference changed')
arch = (packet / 'artifacts/03-architecture-draft.md').read_text()
demo = (packet / 'artifacts/04-demonstrator-plan.md').read_text()
initial = (packet / 'artifacts/01-initial-contract.md').read_text()
for i in range(1, 9):
    if f'R{i:02d}.' not in initial:
        errors.append(f'missing confirmed requirement R{i:02d}')
for prefix, count in [('S', 9), ('T', 13)]:
    for i in range(1, count + 1):
        if not re.search(rf'\| {prefix}{i:02d}(?::| \|)', demo):
            errors.append(f'missing scenario/oracle {prefix}{i:02d}')
for required in ['Native protocol endpoints remain allowed', 'dispatch-intent', 'uncertain', 'incomplete-close', 'Rust', 'unknown']:
    if required not in arch:
        errors.append(f'missing contract topic {required}')
result = {'markdown_files': len(markdown), 'local_links_checked': links, 'selected_source_files_checked': source_files, 'errors': errors, 'evidence_strength': 'attested document structure and source-byte check; not semantic or runtime proof'}
print(json.dumps(result, indent=2))
sys.exit(bool(errors))
