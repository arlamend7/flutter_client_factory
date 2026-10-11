# Disposable TLS fixtures

These are public, non-production test certificates and a disposable private key.
The private CA key is discarded during generation. Trust is configured only in the
individual test's SecurityContext; nothing is installed into system trust.

Regenerate with `bash tool/generate_test_certificates.sh`. The leaf expires after
365 days. CI regenerates it for each run. The whole test directory is excluded
from the published package. Never deploy or reuse this key for real traffic.
