const { contextBridge, ipcRenderer } = require('electron');
const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
// Only the generated, bundled files are readable from the page (never data/raw or anything outside data/).
const DATA_FILE_RE = /^(quran|(translations|words|pages|qcf|tafsir)\/[A-Za-z0-9_.-]+(\/[A-Za-z0-9_.-]+)?)\.json$/;

function readData(rel) {
  if (!DATA_FILE_RE.test(rel) || rel.includes('..')) throw new Error(`Not a data file: ${rel}`);
  return JSON.parse(fs.readFileSync(path.join(DATA_DIR, rel), 'utf8'));
}

// The authentic Madani mushaf fonts are optional (see scripts/fetch-fonts.js); the UI falls back to open fonts without them.
const hasFile = (...p) => fs.existsSync(path.join(__dirname, ...p));
const MUSHAF = {
  qcf: hasFile('fonts', 'mushaf', 'p1.woff2') && hasFile('fonts', 'mushaf', 'p604.woff2') && hasFile('..', 'data', 'qcf', '1.json'),
  hafs: hasFile('fonts', 'mushaf', 'UthmanicHafs.woff2'),
};

contextBridge.exposeInMainWorld('api', {
  mushaf: () => MUSHAF,
  loadQuran: () => readData('quran.json'),
  loadData: readData,
  audio: {
    status: (reciter) => ipcRenderer.invoke('audio:status', reciter),
    usage: (reciter) => ipcRenderer.invoke('audio:usage', reciter),
    download: (reciter, surahs) => ipcRenderer.invoke('audio:download', reciter, surahs),
    cancel: () => ipcRenderer.invoke('audio:cancel'),
    remove: (reciter, surah) => ipcRenderer.invoke('audio:remove', reciter, surah),
    openFolder: () => ipcRenderer.invoke('audio:open-folder'),
    onProgress: (cb) => ipcRenderer.on('audio:progress', (_e, data) => cb(data)),
  },
});
