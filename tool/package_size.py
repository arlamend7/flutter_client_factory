"""Estimate the source archive; pub publish --dry-run is the authoritative list."""
import gzip
import io
import tarfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
excluded_roots = {'.dart_tool', '.git', '.github', 'build', 'coverage', 'packages', 'test', 'tool'}
excluded_names = {'pubspec.lock', 'AGENTS.md', 'analysis-report.json', '.DS_Store'}
files = [p for p in root.rglob('*') if p.is_file()
         and not any(part in excluded_roots for part in p.relative_to(root).parts)
         and p.name not in excluded_names
         and p.suffix != '.docx'
         and not p.relative_to(root).as_posix().startswith('doc/api/')]
buffer = io.BytesIO()
with tarfile.open(fileobj=buffer, mode='w', format=tarfile.USTAR_FORMAT) as archive:
    for path in sorted(files):
        info = tarfile.TarInfo(path.relative_to(root).as_posix())
        data = path.read_bytes()
        info.size = len(data)
        archive.addfile(info, io.BytesIO(data))
source_bytes = sum(p.stat().st_size for p in files if p.is_relative_to(root / 'lib'))
print(f'Runtime Dart source: {source_bytes:,} bytes')
print(f'Estimated included files: {len(files)}')
print(f'Estimated source archive (gzip): {len(gzip.compress(buffer.getvalue(), mtime=0)):,} bytes')
print('Estimate only: compare with dart pub publish --dry-run before release.')
