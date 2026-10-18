"""Structural assessment checks; does not substitute for behavioral evidence."""
from collections import Counter
from pathlib import Path
import hashlib
import json
import re
import subprocess
from urllib.parse import unquote

PROJECT = Path(__file__).resolve().parents[4]
PLANNING = PROJECT.parent
SOURCE = PLANNING.parents[1]
ARC = PROJECT / 'arc01-current-state'
S1 = ARC / 'slice01-plan-assessment/artifacts'
S2 = ARC / 'slice02-implementation-map/artifacts'
S3 = ARC / 'slice03-lfe-audit'
S4 = ARC / 'slice04-rust-audit-and-synthesis'


def read_json(path):
    return json.loads(path.read_text())


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()


corpus = read_json(S1 / '2026.10.17-corpus-inventory.json')
assert len(corpus['files']) == corpus['file_count'] == 157
assert sum(x['lines'] for x in corpus['files']) == corpus['line_count'] == 23420
for item in corpus['files']:
    content = (PLANNING / item['path']).read_bytes()
    assert hashlib.sha256(content).hexdigest() == item['sha256'], item['path']
    assert len(content.splitlines()) == item['lines'], item['path']
print('PASS: 157 corpus hashes unchanged; 23420 logical lines; original/wrapper inventory preserved')

source = read_json(S1 / '2026.10.17-source-map.json')
coverage = read_json(S4 / 'artifacts/2026.10.17-source-coverage.json')
assert len(source['files']) == source['tracked_files'] == 87
assert {x['path'] for x in source['files']} == {x['path'] for x in coverage['files']}
for item in source['files']:
    # Byte hashes are metadata checks, including tracked assets; no semantic asset review.
    assert hashlib.sha256((SOURCE / item['path']).read_bytes()).hexdigest() == item['sha256'], item['path']
assert git(SOURCE, 'rev-parse', 'HEAD') == source['source_pin']
assert not git(SOURCE, 'status', '--porcelain')
for sibling, pin in [('protocol', '9eb7bac6bb8c22b7cb8becc51e45f7316b06f9cf'),
                     ('term', 'ce9238802819f026da30daa6f8fb9e12b618b689')]:
    root = SOURCE.parent / sibling
    assert git(root, 'rev-parse', 'HEAD') == pin
    assert not git(root, 'status', '--porcelain')
print('PASS: 87 source hashes/dispositions; source and both resolved sibling pins clean/unchanged')

rust_guides = read_json(S4 / 'artifacts/2026.10.17-rust-team-guide-coverage.json')
skills = Path('/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills')
assert len(rust_guides['records']) == rust_guides['files'] == 36
assert sum(r['lines'] for r in rust_guides['records']) == rust_guides['lines'] == 32559
for record in rust_guides['records']:
    content = (skills / 'rust-guidelines' / record['path']).read_bytes()
    assert hashlib.sha256(content).hexdigest() == record['sha256']
    assert len(content.splitlines()) == record['lines']
lfe_evidence = (S3 / 'artifacts/2026.10.17-lfe-evidence.md').read_text()
reference_rows = re.findall(r'^\| `(/[^`]+)` \| (\d+) \| `([0-9a-f]{64})` \|', lfe_evidence, re.M)
assert len(reference_rows) == 25
for name, line_count, sha in reference_rows:
    content = Path(name).read_bytes()
    assert hashlib.sha256(content).hexdigest() == sha, name
    assert len(content.splitlines()) == int(line_count), name
erlang_guides = [(name, count) for name, count, _ in reference_rows if '/erlang-guidelines/guides/' in name]
assert len(erlang_guides) == 17 and sum(int(count) for _, count in erlang_guides) == 7220
print('PASS: attributed Rust36/32559 and Erlang17/7220 guide metadata plus Chineual/audit references match installed files; personal reading not inferred')

obligations = read_json(S1 / '2026.10.17-obligation-inventory.json')['rows']
rows = read_json(S2 / '2026.10.17-implementation-map.json')['rows']
assert len(rows) == len(obligations) == 68
assert {r['id'] for r in rows} == {r['id'] for r in obligations}
originals = {r['id']: r for r in obligations}
for row in rows:
    for field in ['id', 'title', 'intent', 'source', 'lines', 'acceptance_summary']:
        assert row[field] == originals[row['id']][field], (row['id'], field)
    lo, hi = row['lines']
    assert 1 <= lo <= hi <= len((PLANNING / row['source']).read_text().splitlines()), row['id']
    assert all(list(SOURCE.glob(f)) for f in row['implementation_paths']), row['id']
counts = Counter(r['current_status'] for r in rows)
assert counts == dict(partial=37, demonstrated=9, absent=9, prospective=5,
                      **{'source-present-unverified': 4}, unverified=2, deferred=1, ambiguous=1)
print('PASS: 68 stable family IDs, original criteria/locators unchanged; statuses=' + str(dict(sorted(counts.items()))))

reports = [('LFE', S3 / 'artifacts/2026.10.17-audit-results-lfe.md', 21),
           ('RUST', S4 / 'artifacts/2026.10.17-audit-results-rust.md', 4),
           ('TOOLS', S4 / 'artifacts/2026.10.17-shared-tooling.md', 2)]
finding_ids = set()
severities = Counter()
for prefix, path, total in reports:
    text = path.read_text()
    pattern = r'^#{2,3} (' + prefix + r'-\d{3})[^\n]*\n([\s\S]*?)(?=^#{2,3} |\Z)'
    findings = re.findall(pattern, text, re.M)
    assert [x[0] for x in findings] == [f'{prefix}-{n:03}' for n in range(1, total + 1)]
    for fid, body in findings:
        header = re.search(r'^#{2,3} ' + fid + r'[^\n]*', text, re.M).group()
        severity = re.search(r'\b(Blocker|High|Medium|Low)\b', header + '\n' + body).group()
        severities[severity] += 1
        finding_ids.add(fid)
synthesis = (S4 / 'artifacts/2026.10.17-audit-modernization-synthesis.md').read_text()
backlog_ids = re.findall(r'^\| ((?:LFE|RUST|TOOLS)-\d{3}) \|', synthesis, re.M)
assert len(backlog_ids) == len(set(backlog_ids)) == 27
assert set(backlog_ids) == finding_ids
assert severities == dict(High=13, Medium=13, Low=1)
assert all(set(r.get('audit_findings', [])) <= finding_ids for r in rows)
print('PASS: 27 unique findings, every backlog row present exactly once; 13 High / 13 Medium / 1 Low')

for path in PROJECT.rglob('*.json'):
    read_json(path)
links = 0
for path in PROJECT.rglob('*.md'):
    for target in re.findall(r'(?<!!)\[[^\]\n]+\]\(([^)]+)\)', path.read_text()):
        target = target.strip().strip('<>')
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith('#'):
            continue
        target = unquote(target.split('#', 1)[0])
        target = re.sub(r':\d+$', '', target)
        resolved = Path(target) if target.startswith('/') else path.parent / target
        assert resolved.exists(), (str(path.relative_to(PROJECT)), target)
        links += 1
print(f'PASS: all Project09 JSON parses; {links} local Markdown link targets exist (anchors/prose claims not inferred)')

for path in [PROJECT / 'ledger.md', ARC / 'ledger.md', *ARC.glob('slice*/ledger.md')]:
    ledger = re.findall(r'^\| ((?:P09|A01|S\d{2})-\d{2}) \|([^\n]*)', path.read_text(), re.M)
    assert len(ledger) == 6, path
    assert all(re.search(r'\| (open|done|deferred|no-op) \|', body) for _, body in ledger)
print('PASS: all six ledgers retain six criteria and explicit dispositions; open acceptance is not silently closed')

# Exact raw .log/.diff evidence can contain diff context whitespace and remains untouched.
for path in PROJECT.rglob('*'):
    if path.is_file() and path.suffix in {'.md', '.json', '.py', '.escript', '.toml', '.rs'}:
        assert not any(line.rstrip() != line for line in path.read_text().splitlines()), path
print('PASS: authored reports/JSON/probe source have no trailing whitespace; raw logs/diffs preserved verbatim')
print('LIMIT: structural checks are self-attested, not independent acceptance of coordinator-authored conclusions')
