# Project instructions

Read `doc/architecture.md` and `CONTRIBUTING.md` before making structural changes.

- Keep this a pure Dart core with no third-party runtime dependencies.
- Keep exactly one class per Dart file; also separate enums and typedefs.
- Organize by networking context first, then responsibility.
- Use early returns and explicit dependency injection.
- Keep default policies under their feature's `defaults/`; samples under `example/`.
- Do not introduce generic helpers/utilities dumping grounds.
- Do not expose placeholders as working features or invent support claims.
- Update public exports and architecture documentation when moving public APIs.
- Run formatting, analysis and relevant tests when a Dart SDK is available.
- If validation cannot run, report that clearly without claiming it passed.
