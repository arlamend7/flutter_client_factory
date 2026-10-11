import {spawn} from 'node:child_process';
import {mkdtemp, readFile, rm} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
const [url] = process.argv.slice(2);
if (!url) throw new Error('Usage: node tool/run_browser_test.mjs http://localhost:PORT/');
const profile = await mkdtemp(path.join(os.tmpdir(), 'flutter-client-factory-chrome-'));
const chrome = process.env.CHROME_EXECUTABLE ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const args = ['--headless','--disable-gpu',`--user-data-dir=${profile}`,'--remote-debugging-port=0','about:blank'];
// Opt in only for disposable CI runners that cannot use Chrome's Linux sandbox.
if (process.env.CHROME_NO_SANDBOX === 'true') args.unshift('--no-sandbox');
const child = spawn(chrome, args, {stdio:['ignore','ignore','inherit']});
let spawnError;
const exited = new Promise(resolve => {
  child.once('exit', resolve);
  child.once('error', error => { spawnError = error; resolve(); });
});
let socket;
try {
  let port;
  for (let i=0;i<100;i++) {
    if (spawnError) throw new Error(`Could not launch Chrome: ${spawnError.message}`);
    if (child.exitCode !== null || child.signalCode !== null) {
      throw new Error(`Chrome exited before startup (code ${child.exitCode}, signal ${child.signalCode}); see browser stderr above.`);
    }
    try { port=(await readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]; break; }
    catch { await new Promise(resolve=>setTimeout(resolve,100)); }
  }
  if (!port) throw new Error('Chrome did not start');
  const tab = await (await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`,{method:'PUT'})).json();
  socket = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{socket.onopen=resolve;socket.onerror=reject;});
  let id=0;
  const pending = new Map();
  socket.onmessage=event=>{const message=JSON.parse(event.data);if(message.id){pending.get(message.id)?.(message);pending.delete(message.id);}};
  const evaluate=expression=>new Promise(resolve=>{const key=++id;pending.set(key,resolve);socket.send(JSON.stringify({id:key,method:'Runtime.evaluate',params:{expression,returnByValue:true}}));});
  let result;
  for(let i=0;i<200;i++){
    const response=await evaluate("document.body?.getAttribute('data-result')");
    result=response.result?.result?.value;
    if(result) break;
    await new Promise(resolve=>setTimeout(resolve,100));
  }
  if(result!=='PASS') throw new Error(result ?? 'Browser test timed out');
  console.log(`PASS browser integration: ${url}`);
} finally {
  socket?.close(); child.kill();
  await exited;
  await rm(profile,{recursive:true,force:true});
}
