import {spawnSync} from 'node:child_process';
import {mkdtempSync, writeFileSync, chmodSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import test from 'node:test';

function runWithChrome(executable) {
  return spawnSync(process.execPath, ['tool/run_browser_test.mjs', 'http://127.0.0.1:1/'], {
    env: {...process.env, CHROME_EXECUTABLE: executable},
    encoding: 'utf8',
    timeout: 5000,
  });
}

test('reports a missing browser executable without hanging during cleanup', () => {
  const result = runWithChrome('/nonexistent/flutter-client-test-chrome');
  assert.equal(result.error, undefined);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Could not launch Chrome/);
  assert.doesNotMatch(result.stderr, /unsettled top-level await/);
});

test('preserves startup diagnostics when Chrome exits before its debug port opens', () => {
  const directory = mkdtempSync(path.join(tmpdir(), 'client-browser-startup-'));
  try {
    const executable = path.join(directory, 'chrome');
    writeFileSync(executable, '#!/bin/sh\necho "Browser startup fixture failure" >&2\nexit 42\n');
    chmodSync(executable, 0o755);
    const result = runWithChrome(executable);
    assert.equal(result.error, undefined);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Chrome exited before startup \(code 42/);
    assert.match(result.stderr, /Browser startup fixture failure/);
    assert.doesNotMatch(result.stderr, /unsettled top-level await/);
  } finally {
    rmSync(directory, {recursive: true, force: true});
  }
});
