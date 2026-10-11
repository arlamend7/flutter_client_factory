# Coding and review conventions

## File organization

- One class per file, including abstract classes, exceptions and small DTOs.
- One enum, extension, or typedef per file as well.
- Use `lower_snake_case.dart`; match the principal declaration's name.
- Keep tests near the mirrored feature path under `test/`.
- Place public exports only in deliberate entry points under `lib/`.
- Import implementation files directly inside `src`; do not import public barrels.

## Folder responsibilities

- `contracts/`: interfaces and callback signatures.
- `models/`: immutable data and closely related invariants.
- `configuration/`: validated options and configuration snapshots.
- `services/`: orchestration, stateful lifecycle, or I/O-facing behavior.
- `helpers/`: small deterministic operations within a specific feature.
- `defaults/`: built-in default values and policies, never sample applications.
- `enums/`: bounded choices.
- `errors/`: contextual exceptions and error descriptors.
- `example/`: runnable sample applications and their sample configuration.

Avoid root-level `utils`, `common`, `misc`, or `manager` dumping grounds. A helper
belongs to its domain. If a true utility is eventually needed, give its directory
a specific purpose such as `encoding/` or `scheduling/`, a clear owner, and tests.
Do not create empty abstractions or placeholder classes for every roadmap item.

## Readability

- Validate invalid states at the start and use early returns.
- Keep the successful path at the lowest practical indentation level.
- Prefer explicit names: `cancellationToken`, `registration`, `transport`.
- Use private methods to name meaningful steps, not to hide one-line expressions.
- Keep classes cohesive; split by responsibility, not an arbitrary line limit.
- Use `final`, immutable snapshots, and defensive copies where ownership changes.
- Document why an ownership or ordering rule exists; avoid comments narrating code.
- Never silently catch errors, silently ignore unsupported options, or invent
  timeout/retry behavior that the transport cannot enforce.

## Lifecycle and async behavior

- Constructors receive dependencies; no mandatory singleton or service locator.
- A factory owns its transports. Client wrappers borrow them.
- Each registration's builder must produce an independently owned transport.
- Document who owns a stream and who cancels or consumes it.
- Retries require replayable bodies and an explicit policy for operation safety.
- Separate operation state from attempt state; never store user credentials in
  globally shared middleware state.
- Avoid unawaited futures unless their ownership and error handling are explicit.

## Validation

Run formatting, analysis and focused tests for changed behavior. Test observable
contracts: disposal isolation, retry bounds, actual I/O cancellation, stream
cleanup, immutable data, middleware order, and platform restrictions. Do not add
tests that merely repeat property assignments or mirror private implementations.
