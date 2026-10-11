"""Verify that the release tag follows vMAJOR.MINOR.PATCH with an optional suffix."""

import os
import re


def main():
    if os.environ.get("GITHUB_REF_TYPE") != "tag":
        raise SystemExit("Publishing requires a pushed version tag")

    tag = os.environ.get("GITHUB_REF_NAME", "")

    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+.*", tag):
        raise SystemExit(
            "Release tag must follow the format vMAJOR.MINOR.PATCH "
            "(e.g., v1.0.0 or v1.2.3-beta)"
        )

    print(f"Verified release tag: {tag}")


if __name__ == "__main__":
    main()