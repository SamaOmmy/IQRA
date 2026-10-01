const { app, BrowserWindow, Menu, shell, protocol, net, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');

// qaudio://a/<reciter>/<surah3><ayah3>.mp3 is served from the local audio cache,
// downloading the verse from everyayah.com first if it isn't cached yet.
protocol.registerSchemesAsPrivileged([
  { scheme: 'qaudio', privileges: { standard: true, secure: true, stream: true, supportFetchAPI: true } },
]);

if (!app.requestSingleInstanceLock()) {
  app.quit();
}

let win;
const audioDir = () => path.join(app.getPath('userData'), 'audio');
const RECITER_RE = /^[A-Za-z0-9_.-]+$/;
const FILE_RE = /^\d{6}\.mp3$/;
const pad3 = (n) => String(n).padStart(3, '0');

let counts = null; // ayah count per surah
function ayahCounts() {
  if (!counts) {
    const quran = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data', 'quran.json'), 'utf8'));
    counts = quran.surahs.map((s) => s.ayahs.length);
  }
  return counts;
}

// ---------- Audio cache ----------
const inflight = new Map();

function ensureFile(reciter, file) {
  const dest = path.join(audioDir(), reciter, file);
  if (fs.existsSync(dest)) return Promise.resolve(dest);
  const key = `${reciter}/${file}`;
  if (!inflight.has(key)) {
    inflight.set(key, (async () => {
      const res = await net.fetch(`https://everyayah.com/data/${reciter}/${file}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());
      await fs.promises.mkdir(path.dirname(dest), { recursive: true });
      await fs.promises.writeFile(`${dest}.part`, buf); // write-then-rename so a crash never leaves a truncated mp3
      await fs.promises.rename(`${dest}.part`, dest);
      return dest;
    })().finally(() => inflight.delete(key)));
  }
  return inflight.get(key);
}

async function reciterFiles(reciter) {
  try {
    return (await fs.promises.readdir(path.join(audioDir(), reciter))).filter((f) => FILE_RE.test(f));
  } catch {
    return [];
  }
}

let job = null; // the running download, if any

async function downloadSurahs(sender, reciter, surahs) {
  const total = surahs.reduce((sum, s) => sum + ayahCounts()[s - 1], 0);
  let done = 0, failed = 0, lastSent = 0;
  const send = (extra = {}) => {
    if (sender.isDestroyed()) return;
    sender.send('audio:progress', { reciter, done, total, failed, running: true, ...extra });
  };

  for (const s of surahs) {
    const count = ayahCounts()[s - 1];
    const queue = Array.from({ length: count }, (_, i) => `${pad3(s)}${pad3(i + 1)}.mp3`);
    const worker = async () => {
      while (queue.length && !job.cancelled && failed < 8) {
        const file = queue.shift();
        let ok = false;
        for (let attempt = 0; attempt < 3 && !ok && !job.cancelled; attempt++) {
          try { await ensureFile(reciter, file); ok = true; } catch { /* retry */ }
        }
        if (ok) done++; else failed++;
        const now = Date.now();
        if (now - lastSent > 150) { lastSent = now; send({ surah: s }); }
      }
    };
    await Promise.all(Array.from({ length: 4 }, worker));
    send({ surah: s });
    if (job.cancelled || failed >= 8) break;
  }
  return { done, total, failed, cancelled: job.cancelled };
}

ipcMain.handle('audio:status', async (_e, reciter) => {
  if (!RECITER_RE.test(reciter)) return [];
  const have = new Array(114).fill(0);
  for (const f of await reciterFiles(reciter)) have[+f.slice(0, 3) - 1]++;
  return have;
});

ipcMain.handle('audio:usage', async (_e, reciter) => {
  if (!RECITER_RE.test(reciter)) return { files: 0, bytes: 0 };
  let bytes = 0;
  const files = await reciterFiles(reciter);
  for (const f of files) {
    try { bytes += (await fs.promises.stat(path.join(audioDir(), reciter, f))).size; } catch { /* removed meanwhile */ }
  }
  return { files: files.length, bytes };
});

ipcMain.handle('audio:download', async (e, reciter, surahs) => {
  if (!RECITER_RE.test(reciter) || !Array.isArray(surahs) || !surahs.every((s) => Number.isInteger(s) && s >= 1 && s <= 114)) {
    return { error: 'Invalid request' };
  }
  if (job) return { error: 'A download is already running' };
  job = { cancelled: false };
  try {
    const result = await downloadSurahs(e.sender, reciter, surahs);
    if (!e.sender.isDestroyed()) e.sender.send('audio:progress', { reciter, running: false, ...result });
    return result;
  } finally {
    job = null;
  }
});

ipcMain.handle('audio:cancel', () => { if (job) job.cancelled = true; });

ipcMain.handle('audio:remove', async (_e, reciter, surah) => {
  if (job) return { error: 'Wait for the running download to finish or cancel it first' };
  if (!RECITER_RE.test(reciter)) return { error: 'Invalid request' };
  if (surah == null) {
    await fs.promises.rm(path.join(audioDir(), reciter), { recursive: true, force: true });
    return {};
  }
  if (!Number.isInteger(surah) || surah < 1 || surah > 114) return { error: 'Invalid request' };
  for (const f of await reciterFiles(reciter)) {
    if (f.startsWith(pad3(surah))) await fs.promises.rm(path.join(audioDir(), reciter, f), { force: true });
  }
  return {};
});

ipcMain.handle('audio:open-folder', async () => {
  await fs.promises.mkdir(audioDir(), { recursive: true });
  return shell.openPath(audioDir());
});

// ---------- Window ----------
function createWindow() {
  win = new BrowserWindow({
    width: 1280,
    height: 820,
    minWidth: 900,
    minHeight: 600,
    title: "Qur'an Reader",
    backgroundColor: '#f6f1e7',
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false, // preload reads the bundled data files with fs
    },
  });

  Menu.setApplicationMenu(null);
  win.loadFile(path.join(__dirname, 'index.html'));
  win.once('ready-to-show', () => win.show());

  // Never navigate the app window away; open any external link in the default browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (e) => e.preventDefault());
}

app.on('second-instance', () => {
  if (win) {
    if (win.isMinimized()) win.restore();
    win.focus();
  }
});

app.whenReady().then(() => {
  protocol.handle('qaudio', async (req) => {
    const [, reciter, file] = new URL(req.url).pathname.split('/');
    if (!RECITER_RE.test(reciter || '') || !FILE_RE.test(file || '')) return new Response('Bad request', { status: 400 });
    try {
      const dest = await ensureFile(reciter, file);
      return await net.fetch(pathToFileURL(dest).toString(), { headers: req.headers }); // keeps Range/seek support
    } catch {
      return new Response('Audio unavailable', { status: 504 });
    }
  });
  createWindow();
});
app.on('window-all-closed', () => app.quit());
