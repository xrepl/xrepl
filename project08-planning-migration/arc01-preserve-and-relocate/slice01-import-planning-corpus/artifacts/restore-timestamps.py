#!/usr/bin/env python3
"""Verify or restore unchanged legacy records; explicit --apply enables writes."""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import struct
import sys


class AttrList(ctypes.Structure):
    _fields_ = [('bitmapcount', ctypes.c_ushort), ('reserved', ctypes.c_ushort),
                ('commonattr', ctypes.c_uint32), ('volattr', ctypes.c_uint32),
                ('dirattr', ctypes.c_uint32), ('fileattr', ctypes.c_uint32),
                ('forkattr', ctypes.c_uint32)]


def creation_ns(path, value=None):
    """Darwin attr.h: ATTR_CMN_CRTIME; preserve native timespec precision."""
    if sys.platform != 'darwin':
        return None
    attrs = AttrList(5, 0, 0x00000200, 0, 0, 0, 0)
    lib = ctypes.CDLL(None, use_errno=True)
    if value is None:
        buf = ctypes.create_string_buffer(20)
        result = lib.getattrlist(os.fsencode(path), ctypes.byref(attrs), buf, 20, 1)
        if result:
            raise OSError(ctypes.get_errno(), 'getattrlist creation time', str(path))
        sec, nano = struct.unpack_from('=qq', buf.raw, 4)
        return sec * 1_000_000_000 + nano
    sec, nano = divmod(value, 1_000_000_000)
    data = ctypes.create_string_buffer(struct.pack('=qq', sec, nano))
    if lib.setattrlist(os.fsencode(path), ctypes.byref(attrs), data, 16, 1):
        raise OSError(ctypes.get_errno(), 'setattrlist creation time', str(path))
    return creation_ns(path)


def safe_path(root, name):
    rel = PurePosixPath(name)
    if (not name or rel.is_absolute() or '..' in rel.parts
            or any(p in {'.git', '.aws', '.claude', '.codex', '.agents'} for p in rel.parts)):
        raise ValueError('unsafe relative path: ' + str(name))
    target = root.joinpath(*rel.parts)
    cur = root
    for part in rel.parts:
        cur = cur / part
        if cur.is_symlink():
            raise ValueError('symlink refused: ' + str(cur))
    if not target.resolve().is_relative_to(root):
        raise ValueError('path escapes selected root: ' + name)
    return target


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def records(manifest, layout):
    result = []
    for row in manifest['entries']:
        if row['kind'] == 'file' and row.get('disposition') != 'migrate':
            continue
        name = row.get('destination') if layout == 'canonical' else row['source']
        if name:
            result.append((row, name))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, type=Path)
    parser.add_argument('--manifest', type=Path, default=Path(__file__).with_name('source-inventory.json'))
    parser.add_argument('--layout', choices=['canonical', 'original'], default='canonical')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--recover-from', type=Path, help='Copy canonical payloads into an empty original-layout root; requires --apply.')
    parser.add_argument('--creation', action='store_true', help='Also verify/restore exact native creation times when recorded and supported.')
    args = parser.parse_args()
    if args.root.is_symlink():
        raise ValueError('root symlink refused')
    root = args.root.resolve()
    data = json.loads(args.manifest.read_text())
    native_path = args.manifest.with_name('native-creation-times.json')
    native = json.loads(native_path.read_text())['birthtime_ns_by_source'] if native_path.exists() else {}
    selected = records(data, args.layout)
    if len({name for _, name in selected}) != len(selected):
        raise ValueError('duplicate destination paths')
    recovery = args.recover_from is not None
    if recovery and (not args.apply or args.layout != 'original'):
        raise ValueError('recovery requires --apply --layout original')
    if recovery and root.exists() and (not root.is_dir() or any(root.iterdir())):
        raise ValueError('original-layout recovery root must be empty or absent')
    if not recovery and not root.is_dir():
        raise ValueError('selected root must be an existing directory')
    source_root = args.recover_from.resolve() if recovery else None
    prepared = []
    # Validate the complete set before copying, chmod, creation-time or utime writes.
    for row, name in selected:
        if row['kind'] not in {'file', 'directory'}:
            raise ValueError('unsupported object kind')
        target = safe_path(root, name)
        probe = safe_path(source_root, row['destination']) if recovery and row['kind'] == 'file' else target
        if row['kind'] == 'file':
            if not stat.S_ISREG(probe.lstat().st_mode):
                raise ValueError('regular file required: ' + str(probe))
            if digest(probe) != row['sha256']:
                raise ValueError('modified payload refused: ' + str(probe))
        elif not recovery and not stat.S_ISDIR(target.lstat().st_mode):
            raise ValueError('directory required: ' + str(target))
        prepared.append((row, target, probe))
    if recovery:
        root.mkdir(parents=True, exist_ok=True)
        for row, target, probe in prepared:
            if row['kind'] == 'directory':
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(probe, target)
    # Deepest directories last, after files, so nested writes cannot reset dates.
    ordered = sorted(prepared, key=lambda item: (item[0]['kind'] == 'directory', -len(item[1].parts)))
    creation_unsupported = []
    if args.apply:
        for row, target, _ in ordered:
            os.chmod(target, int(row['mode'], 8), follow_symlinks=False)
            if args.creation and row['source'] in native:
                if sys.platform == 'darwin':
                    creation_ns(target, native[row['source']])
                else:
                    creation_unsupported.append(row['source'])
            os.utime(target, ns=(row['atime_ns'], row['mtime_ns']), follow_symlinks=False)
    mismatches = []
    for row, target, _ in prepared:
        s = target.stat()
        if s.st_mtime_ns != row['mtime_ns']:
            mismatches.append({'path': str(target.relative_to(root)), 'field': 'mtime_ns', 'expected': row['mtime_ns'], 'actual': s.st_mtime_ns})
        if stat.S_IMODE(s.st_mode) != int(row['mode'], 8):
            mismatches.append({'path': str(target.relative_to(root)), 'field': 'mode'})
        if args.creation and row['source'] in native:
            if sys.platform == 'darwin' and creation_ns(target) != native[row['source']]:
                mismatches.append({'path': str(target.relative_to(root)), 'field': 'birthtime_ns'})
            elif sys.platform != 'darwin' and row['source'] not in creation_unsupported:
                creation_unsupported.append(row['source'])
    print(json.dumps({'layout': args.layout, 'apply': args.apply, 'files': sum(r['kind'] == 'file' for r, _, _ in prepared), 'directories': sum(r['kind'] == 'directory' for r, _, _ in prepared), 'mismatches': mismatches, 'creation_unsupported': creation_unsupported, 'creation_not_requested': not args.creation, 'ctime': 'recorded only; OS-maintained', 'atime': 'restored snapshot value on apply; subsequent reads may change it'}, indent=2))
    return 1 if mismatches else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('REFUSED: ' + str(exc), file=sys.stderr)
        sys.exit(2)
