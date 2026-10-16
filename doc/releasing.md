# Releasing 1.0.3 and checking package quality

Both package manifests are version 1.0.3 and prepared for publication. Preparing
metadata does not publish packages or create a Git tag. MIT licensing is selected.
Repository: https://github.com/arlamend7/flutter_client_factory.

## Validate the checkout

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example tool
dart analyze lib test example tool
bash tool/generate_test_certificates.sh
dart test
python3 tool/check_structure.py
dart doc
python3 tool/package_size.py
```

Native tests need loopback sockets. Regenerate TLS fixtures before expiry; CI does
so per run. `tool/verify_browser.sh` uses Dart, Node 22+ and Chrome to execute JS/Wasm
against local fixtures. Test separately with Dart 3.4.4 and its own dependency
resolution; a newer lockfile is not minimum-SDK evidence.

For the adapter, run Flutter pub get, analyze and test inside
`packages/flutter_client_factory_widgets`, and resolve its example too. Tracked
`pubspec_overrides.yaml` files enable local core development without a path dependency
in the publishable manifest. They are excluded from archives. A local-override
score is not proof of hosted dependency resolution.

## Audit and inspect publication contents

[Pub scoring](https://pub.dev/help/scoring) evaluates the whole package, not each
use-case document. Documentation contributes 20 of the currently available 160
points. It checks an example and public API comments, not completeness of every
application scenario. Likes, downloads, device testing and correctness are separate.
The hosted score is calculated by pub.dev after publication.

Use current pana in a disposable copy; it modifies its analysis directory. Audit
core and adapter independently. The actual public repository must contain matching
publishable manifests; local files alone cannot satisfy repository verification.
Do not replace real metadata or suppress checks to claim a maximum score.

```sh
dart pub global activate pana
dart pub global run pana --json /path/to/disposable/core
dart pub publish --dry-run
```

Pass --flutter-sdk /path/to/flutter for adapter analysis. The dry-run archive list
is authoritative. Preserve README, CHANGELOG, LICENSE, examples and user docs.
Exclude generated API output, caches, development overrides, tests/tools, the nested
adapter from core, and attachments. Validation and quality-audit workflows never publish packages. The dedicated
publication workflows publish only on matching package version tags.

## Release order

1. Review and push source and both matching 1.0.3 manifests to GitHub.
2. Rerun package audits and inspect every unresolved report item.
3. Validate the core dry run; publish only when explicitly authorized.
4. After a compatible core release is hosted, validate the adapter without dependency overrides.
   Resolve flutter_client_factory ^1.0.0 from pub.dev.
5. Repeat adapter analysis/tests/audit/dry run with hosted dependencies, then
   publish it only when explicitly authorized.
6. Create release tags/notes when authorized and retain audit outputs.

The manual quality workflow audits core without publishing. Enable its optional
adapter audit only after core publication; that job removes development overrides.
See the [1.0.0 release audit](release_audit.md) for actual scores and remaining gaps,
and [validation](validation.md) for the historical checks.

Do not pass --dartdoc-version sdk to pana with this installed SDK: that mode supplies
unsupported options. Default standalone dartdoc works; manual dart doc is also valid.


## GitHub Pages deployment

[deploy-docs.yml](../.github/workflows/deploy-docs.yml) follows the reference
repository's validation-then-deploy pattern. In GitHub **Settings → Pages**, select
**GitHub Actions** as the source. Allow the `main` branch in the `github-pages`
environment deployment rules.

A successful **Validate packages** run from a push to `main` builds documentation
from that exact commit. Pull requests and tag publication runs do not deploy docs.
The site includes core and Flutter adapter API references and links to the guides.
Its expected URL is https://arlamend7.github.io/flutter_client_factory/ once the
first deployment succeeds. It documents main, not a pinned release.

## Automated package publication

The [official Dart publishing guide](https://dart.dev/tools/pub/automated-publishing)
requires the first version of each new package to be published manually. Publish
core first; after it resolves from pub.dev, validate and publish the adapter using
hosted dependencies. These workflow files do not bypass that initial setup.

After each package exists, open its pub.dev **Admin → Automated publishing** settings
and enable GitHub Actions for repository `arlamend7/flutter_client_factory`:

| Package | Exact pub.dev tag pattern | Workflow |
| --- | --- | --- |
| flutter_client_factory | `flutter_client_factory-v{{version}}` | [publish.yml](../.github/workflows/publish.yml) |
| flutter_client_factory_widgets | `flutter_client_factory_widgets-v{{version}}` | [publish-widgets.yml](../.github/workflows/publish-widgets.yml) |

No stored pub.dev credentials are needed; publishing uses temporary OIDC tokens.
These workflows do not declare a pub.dev deployment environment. If you enable a
required environment on pub.dev, configure the matching environment in the core
reusable-workflow inputs and adapter publish job before tagging a release.

For each subsequent release, update its manifest and changelog, commit the changes,
and push the package-specific tag whose version exactly matches the manifest.
For example, core version 1.0.1 uses `flutter_client_factory-v1.0.1`. Pushing that tag
is the publication trigger. Tags for the adapter are independent; publish any newly
required core version first and wait until it resolves from pub.dev.

Both workflows verify the tag and run the full reusable validation workflow before
publishing. Core uses Dart's maintained reusable publisher. The adapter uses a
custom publishing job to remove local overrides in a disposable copy, resolve the
hosted core, analyze and test again, then perform a dry run before publication.
Ordinary pushes and pull requests only validate. Workflow executions, Pages setup,
and pub.dev automated-publishing settings must be verified on the remote services;
local YAML validation does not establish successful deployment or publication.
