import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

const [url] = process.argv.slice(2);

if (!url) {
  throw new Error(
    'Usage: node tool/run_browser_test.mjs http://localhost:PORT/'
  );
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const profile = await mkdtemp(
  path.join(os.tmpdir(), 'flutter-client-factory-chrome-')
);

const chrome =
  process.env.CHROME_EXECUTABLE ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const args = [
  '--headless',
  '--disable-gpu',
  `--user-data-dir=${profile}`,
  '--remote-debugging-port=0',
  'about:blank',
];

// Opt in only for disposable CI runners that cannot use Chrome's Linux sandbox.
if (process.env.CHROME_NO_SANDBOX === 'true') {
  args.unshift('--no-sandbox');
}

const child = spawn(chrome, args, {
  stdio: ['ignore', 'ignore', 'inherit'],
});

let spawnError;

// Wait for Chrome to exit completely before cleaning up its profile.
const exited = new Promise((resolve) => {
  child.once('close', resolve);

  child.once('error', (error) => {
    spawnError = error;
    resolve();
  });
});

let socket;

try {
  // --------------------------------------------------
  // Wait for Chrome DevTools to become available
  // --------------------------------------------------

  let port;

  for (let i = 0; i < 100; i++) {
    if (spawnError) {
      throw new Error(
        `Could not launch Chrome: ${spawnError.message}`
      );
    }

    if (child.exitCode !== null || child.signalCode !== null) {
      throw new Error(
        `Chrome exited before startup ` +
        `(code ${child.exitCode}, signal ${child.signalCode}); ` +
        `see browser stderr above.`
      );
    }

    try {
      const content = await readFile(
        path.join(profile, 'DevToolsActivePort'),
        'utf8'
      );

      port = content.split('\n')[0];
      break;
    } catch {
      await sleep(100);
    }
  }

  if (!port) {
    throw new Error('Chrome did not start');
  }

  // --------------------------------------------------
  // Open browser test page
  // --------------------------------------------------

  const response = await fetch(
    `http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`,
    { method: 'PUT' }
  );

  if (!response.ok) {
    throw new Error(
      `Failed to create Chrome tab: HTTP ${response.status}`
    );
  }

  const tab = await response.json();

  // --------------------------------------------------
  // Connect to Chrome DevTools Protocol
  // --------------------------------------------------

  socket = new WebSocket(tab.webSocketDebuggerUrl);

  await new Promise((resolve, reject) => {
    socket.onopen = resolve;
    socket.onerror = reject;
  });

  let id = 0;
  const pending = new Map();

  socket.onmessage = (event) => {
    const message = JSON.parse(event.data);

    if (message.id !== undefined) {
      const callback = pending.get(message.id);

      if (callback) {
        callback(message);
        pending.delete(message.id);
      }
    }
  };

  // --------------------------------------------------
  // Execute JavaScript inside Chrome
  // --------------------------------------------------

  const evaluate = (expression) =>
    new Promise((resolve, reject) => {
      const key = ++id;

      const timeout = setTimeout(() => {
        pending.delete(key);
        reject(new Error('Chrome evaluation timed out'));
      }, 10000);

      pending.set(key, (response) => {
        clearTimeout(timeout);

        if (response.error) {
          reject(new Error(response.error.message));
        } else {
          resolve(response);
        }
      });

      socket.send(
        JSON.stringify({
          id: key,
          method: 'Runtime.evaluate',
          params: {
            expression,
            returnByValue: true,
          },
        })
      );
    });

  // --------------------------------------------------
  // Wait for browser integration test result
  // --------------------------------------------------

  let result;

  for (let i = 0; i < 200; i++) {
    const response = await evaluate(
      "document.body?.getAttribute('data-result')"
    );

    result = response.result?.result?.value;

    if (result) {
      break;
    }

    await sleep(100);
  }

  if (result !== 'PASS') {
    throw new Error(result ?? 'Browser test timed out');
  }

  console.log(`PASS browser integration: ${url}`);

} finally {
  // --------------------------------------------------
  // 1. Close WebSocket connection
  // --------------------------------------------------

  if (socket) {
    try {
      socket.close();
    } catch (error) {
      console.warn(
        `Warning: Could not close WebSocket: ${error.message}`
      );
    }
  }

  // --------------------------------------------------
  // 2. Terminate Chrome gracefully
  // --------------------------------------------------

  if (child.exitCode === null && child.signalCode === null) {
    child.kill('SIGTERM');
  }

  // --------------------------------------------------
  // 3. Force termination if Chrome does not exit
  // --------------------------------------------------

  const killTimeout = setTimeout(() => {
    if (child.exitCode === null && child.signalCode === null) {
      console.warn(
        'Chrome did not exit gracefully. Sending SIGKILL.'
      );

      child.kill('SIGKILL');
    }
  }, 5000);

  try {
    await exited;
  } finally {
    clearTimeout(killTimeout);
  }

  // --------------------------------------------------
  // 4. Clean up temporary Chrome profile
  // --------------------------------------------------

  try {
    await rm(profile, {
      recursive: true,
      force: true,
      maxRetries: 20,
      retryDelay: 250,
    });
  } catch (error) {
    // Cleanup failures should not override successful tests.
    console.warn(
      `Warning: Could not remove Chrome profile: ${profile}\n` +
      `Reason: ${error.message}`
    );
  }
}