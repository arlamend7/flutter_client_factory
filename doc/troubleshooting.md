# Errors, cleanup, and troubleshooting

| Symptom | Explanation / next step |
| --- | --- |
| A 404/500 did not throw | Raw HTTP methods return responses. Call requireSuccess or handle the status and body yourself. |
| JSON parsing fails for HEAD/204 | Empty bodies are not JSON. Dispose or read text as appropriate. |
| Response was already listened to | The body is single-consumption. Use buffer for a reusable snapshot. |
| Buffer limit exceeded | Stream the body, or set an intentional maxBytes bound. Readers still dispose on failure. |
| /api/ disappeared from the URL | A leading slash resolves from the origin root. Use users rather than /users to preserve a base path. |
| Request retries unexpectedly multiply | Every resender repeats downstream policies; inspect ordering and budgets. |
| Timeout appears while reading | Overall deadlines remain active until body consumption/disposal, not just response headers. |
| Request timeout override has no effect on another limit | Explicit timeout middleware and transport connect/idle limits are independent. |
| Disposing a client did not cancel its request | Wrapper disposal blocks new sends. Cancel the operation token to abort active work. |
| Factory close waits | An active response lease is draining; consume/dispose responses. Grace and transport shutdown periods are separate. |
| A test sees no request yet | Async middleware may be pending. Use waitForOne with a bounded timeout. |
| Test verification fails after matching | A matched request must also be completed with flush/fail or intentionally canceled. |
| Browser header/CORS/upload failures | Browser policies and upload limits apply; see platforms.md. |
| Dependency resolution fails for adapter 1.0.0 | Publish the core first; local development uses pubspec_overrides.yaml. |

Network failures, cancellation, timeout, JSON decoding, and explicit status rejection
are different cases. Preserve original errors/stack traces when mapping them to your
application's error model. HttpStatusException contains metadata, not a buffered
error body; inspect the raw response when server error details are needed.

When requesting help, include package/SDK versions, platform, a minimal example,
interceptor order, and sanitized logs. Never include bearer tokens, cookies, client
private keys, or personal data. Follow [security guidance](../SECURITY.md) for
vulnerabilities. GitHub issue forms collect the necessary reproduction details.
