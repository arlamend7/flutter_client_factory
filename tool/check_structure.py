"""Check structural conventions without claiming Dart compilation succeeds."""

import re
from pathlib import Path


def snake_case(name):
    name = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name).lower()


def main():
    root = Path(__file__).resolve().parent.parent
    errors = []
    files = sorted(root.glob("lib/**/*.dart"))
    files += sorted(root.glob("example/**/*.dart"))
    files += sorted(root.glob("test/**/*.dart"))
    files += sorted(root.glob("tool/**/*.dart"))
    files += [p for p in root.glob("packages/**/*.dart")
              if not any(part in {'.dart_tool', 'build', '.widget_preview'} for part in p.parts)]

    for path in files:
        text = path.read_text()
        declarations = re.findall(
            r"^(?:(?:abstract|base|final|interface|sealed)\s+)*"
            r"(?:class|enum|mixin|typedef|extension(?:\s+type)?)\s+(\w+)",
            text,
            re.MULTILINE,
        )
        if len(declarations) > 1:
            errors.append(f"{path.relative_to(root)}: multiple declarations")
        if len(declarations) == 1 and path.stem != snake_case(declarations[0]):
            errors.append(f"{path.relative_to(root)}: declaration/file mismatch")

        for target in re.findall(r"^(?:import|export)\s+'([^']+)'", text, re.MULTILINE):
            if target.startswith("package:flutter_client_factory/"):
                resolved = root / "lib" / target.split("/", 1)[1]
            elif ":" in target:
                continue
            else:
                resolved = path.parent / target
            if not resolved.is_file():
                errors.append(f"{path.relative_to(root)}: missing {target}")

        if path.is_relative_to(root / "lib"):
            if re.search(r"(?:import|export)\s+'package:(?!flutter_client_factory/)", text):
                errors.append(f"{path.relative_to(root)}: external runtime dependency")

    if errors:
        raise SystemExit("\n".join(errors))

    print(f"Structure checks passed for {len(files)} Dart files.")
    print("Checked declaration/file naming, imports, exports, and runtime imports.")
    print("Dart formatting, analysis, and runtime tests are separate checks.")


if __name__ == "__main__":
    main()
