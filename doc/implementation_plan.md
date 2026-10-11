# Implementation and release status

The implementation now contains native/browser HTTP, the client factory, bodies,
policies, authentication, cache, diagnostics, test controller, native downloads and
cookies, persistent protocols, resources, and the separate Flutter adapter.

Release work proceeds in this order:

1. Run formatting, static analysis, structural checks and all regression tests.
2. Run local native HTTP/TLS/socket tests and browser JavaScript/Wasm harnesses.
3. Resolve and test with the minimum Dart SDK independently of the latest lockfile.
4. Review generated API docs, examples, supported-platform claims, package contents
   and representative release artifact sizes.
5. Confirm the public package name. The owner creates its public GitHub repository.
6. Add real repository, issue tracker and documentation links. Audit both packages
   with pana and pub's dry run; fix actionable findings.
7. Replace the adapter's local path dependency with the published core version and
   repeat validation. The core must be published before its dependent adapter.
8. Enable publication only for the reviewed release. Tag releases and maintain a
   changelog and compatibility matrix.

Tests target observable behavior and edge cases; they are not a proof of all possible
network schedules or platform implementations. The exact completed runs and any
remaining validation gaps are recorded in `doc/validation.md`.
