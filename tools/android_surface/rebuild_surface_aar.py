#!/usr/bin/env python3
"""Recompile only the pinned Godot GLSurfaceView family for isolated diagnostics.
Never modifies the distributed preset, engine native libraries, or the source AAR on failure.
"""
import argparse
import difflib
import hashlib
import io
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import zipfile

SOURCE = Path(__file__).parent / 'upstream/GLSurfaceView.java'
HARNESS = Path(__file__).parent / 'SurfaceLatchHarness.java'
UPSTREAM_BLOB = '8b25fdfeceb6dcc273646005137a92f161755558'
PREFIX = 'org/godotengine/godot/gl/GLSurfaceView'

def digest(data):
    return hashlib.sha256(data).hexdigest()

def patched_source(data, variant):
    blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    if blob != UPSTREAM_BLOB:
        raise ValueError('Upstream source drift: expected exact Godot 4.6.3 GLSurfaceView blob')
    if variant == 'control':
        return data
    if variant != 'latched':
        raise ValueError('Unknown surface variant')
    text = data.decode('utf-8')
    edits = [
        ('package org.godotengine.godot.gl;', '// Modified by NULL//SWARM: diagnostic nonblocking lifecycle-edge latch.\n// Original pinned Godot 4.6.3 source and Apache-2.0 header retained.\npackage org.godotengine.godot.gl;'),
        ('\t\tprivate boolean mSurfaceIsBad;', '\t\tprivate boolean mSurfaceIsBad;\n\t\tprivate boolean mSurfaceRecreatePending;'),
        ('\t\t\t\tmHasSurface = true;', '\t\t\t\tmHasSurface = true;\n\t\t\t\tmSurfaceRecreatePending = true;'),
        ('\t\t\t\tmHasSurface = false;', '\t\t\t\tmHasSurface = false;\n\t\t\t\tmSurfaceRecreatePending = true;'),
        ('\t\t\t\t\t\t\t// Have we lost the SurfaceView surface?', '\t\t\t\t\t\t\tconsumePendingSurfaceChangeLocked();\n\n\t\t\t\t\t\t\t// Have we lost the SurfaceView surface?'),
        ('\t\tprivate void guardedRun() throws InterruptedException {', '''\t\t// NULL//SWARM diagnostic patch: consume lifecycle edges on the GL thread.
		// Caller holds sGLThreadManager; no UI-thread wait or context reset is added.
		private void consumePendingSurfaceChangeLocked() {
			if (mSurfaceRecreatePending) {
				stopEglSurfaceLocked();
				mSurfaceIsBad = false;
				mSurfaceRecreatePending = false;
				sGLThreadManager.notifyAll();
			}
		}

		private void guardedRun() throws InterruptedException {'''),
    ]
    for old, new in edits:
        if text.count(old) != 1:
            raise ValueError('Ambiguous patch anchor')
        text = text.replace(old, new, 1)
    return text.encode('utf-8')

def replace_entries(data, updates, predicate):
    """Keep every unrelated entry byte-for-byte, including resources/native libs."""
    output = io.BytesIO()
    with zipfile.ZipFile(io.BytesIO(data)) as source, zipfile.ZipFile(output, 'w') as target:
        names = source.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate ZIP entries')
        existing = {name for name in names if predicate(name)}
        if existing != set(updates):
            raise ValueError(f'Compiled class set differs: missing={existing-set(updates)}, extra={set(updates)-existing}')
        for info in source.infolist():
            target.writestr(info, updates[info.filename] if info.filename in updates else source.read(info.filename))
    return output.getvalue()

def class_family(name):
    return name.endswith('.class') and (name == PREFIX + '.class' or name.startswith(PREFIX + '$'))

def rebuild(aar, android_jar, output_dir, variant):
    original = aar.read_bytes()
    source = SOURCE.read_bytes()
    changed = patched_source(source, variant)
    output_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(original)) as archive:
        jar = archive.read('classes.jar')
        unchanged = {name: digest(archive.read(name)) for name in archive.namelist() if name != 'classes.jar'}
        native = {k:v for k,v in unchanged.items() if k.endswith('.so')}
    with zipfile.ZipFile(io.BytesIO(jar)) as archive:
        header = archive.read(PREFIX + '.class')[:8]
        if header[:4] != b'\xca\xfe\xba\xbe':
            raise ValueError('Invalid upstream class')
        major = struct.unpack('>H', header[6:8])[0]
        release = major - 44
        if release not in (8, 11, 17, 21):
            raise ValueError(f'Unreviewed Java bytecode version: {major}')
    with tempfile.TemporaryDirectory(prefix='null-swarm-surface-') as tmp:
        work = Path(tmp); java = work/'GLSurfaceView.java'; java.write_bytes(changed)
        classes = work/'classes'; classes.mkdir()
        compiler = subprocess.check_output(['javac', '-version'], text=True, stderr=subprocess.STDOUT).strip()
        subprocess.run(['javac', '--release', str(release), '-cp', str(android_jar), '-d', str(classes), str(java)], check=True, timeout=120)
        subprocess.run(['javac', '--release', str(release), '-cp', str(classes) + ':' + str(android_jar), '-d', str(classes), str(HARNESS)], check=True, timeout=120)
        host = subprocess.run(['java', '-cp', str(classes) + ':' + str(android_jar), 'org.godotengine.godot.gl.SurfaceLatchHarness', variant], check=True, capture_output=True, text=True, timeout=15)
        print(host.stdout, end='')
        updates = {p.relative_to(classes).as_posix(): p.read_bytes() for p in classes.rglob('*.class') if class_family(p.relative_to(classes).as_posix())}
        new_jar = replace_entries(jar, updates, class_family)
        modified = replace_entries(original, {'classes.jar': new_jar}, lambda n: n == 'classes.jar')
    with zipfile.ZipFile(io.BytesIO(modified)) as archive:
        assert {name:digest(archive.read(name)) for name in archive.namelist() if name != 'classes.jar'} == unchanged
    with zipfile.ZipFile(io.BytesIO(jar)) as before, zipfile.ZipFile(io.BytesIO(new_jar)) as after:
        retained = [n for n in before.namelist() if not class_family(n)]
        assert all(before.read(n) == after.read(n) for n in retained)
    (output_dir/'GLSurfaceView.java').write_bytes(changed)
    (output_dir/'source.diff').write_text(''.join(difflib.unified_diff(source.decode().splitlines(True), changed.decode().splitlines(True), fromfile='official-4.6.3/GLSurfaceView.java', tofile=variant+'/GLSurfaceView.java')))
    receipt = {'variant':variant,'upstream_git_blob':UPSTREAM_BLOB,'original_source_sha256':digest(source),'compiled_source_sha256':digest(changed),'original_aar_sha256':digest(original),'modified_aar_sha256':digest(modified),'java_release':release,'compiler':compiler,'recompiled_classes':sorted(updates),'unchanged_other_classes':len(retained),'native_libraries_sha256':native,'nonclass_aar_entries_unchanged':True,'host_logic':host.stdout.strip(),'scope':'Diagnostic Java surface family only. Native engine/resources unchanged; real Android recovery is a separate test.'}
    (output_dir/'surface-build.json').write_text(json.dumps(receipt, indent=2)+'\n')
    # All compilation/host/archive validation completed before replacing the disposable input.
    replacement = aar.with_suffix(aar.suffix+'.tmp'); replacement.write_bytes(modified); replacement.replace(aar)
    return receipt

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aar', type=Path, required=True)
    parser.add_argument('--android-jar', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--variant', choices=['control','latched'], required=True)
    args=parser.parse_args()
    print('SURFACE_BUILD', json.dumps(rebuild(args.aar, args.android_jar, args.output, args.variant)))

if __name__=='__main__':main()
