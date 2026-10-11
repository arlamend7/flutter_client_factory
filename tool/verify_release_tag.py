"""Reject release tags that do not identify the selected package and version."""

import os
from pathlib import Path
import re
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: verify_release_tag.py PACKAGE_DIRECTORY")

    manifest = (Path(sys.argv[1]) / "pubspec.yaml").read_text()
    fields = {}
    for key in ("name", "version"):
        match = re.search(rf"^{key}:\s*([^\n#]+)", manifest, re.MULTILINE)
        if match is None:
            raise SystemExit(f"Missing {key} in package manifest")
        fields[key] = match.group(1).strip().strip("\"'")

    expected = f"{fields['name']}-v{fields['version']}"
    if os.environ.get("GITHUB_REF_TYPE") != "tag":
        raise SystemExit("Publishing requires a pushed version tag")
    if os.environ.get("GITHUB_REF_NAME") != expected:
        raise SystemExit(f"Release tag must exactly match {expected}")
    print(f"Verified release tag: {expected}")


if __name__ == "__main__":
    main()
