'use strict';
// Packs the data the Flutter app bundles into a few large JSON files (faster to load than hundreds of small ones):
//   node scripts/prepare-flutter-assets.js
//
//   assets/data/quran.json      surahs, ayahs, default translation (copied)
//   assets/data/pages.json      [604][words] = [surah, ayah, text, line, flags]
//   assets/data/words.json      [114][ayahs][words] = [arabic, meaning, transliteration, uthmani]
//   assets/data/discover/*.json hisn, azkar, nawawi, hadith (copied)
//   assets/qcf/qcf.json         [604][glyphs]  (licensed glyph data: git-ignored, absent from public builds)
//
// Other translations and the tafsirs are not bundled; the app downloads them on demand from this repository and caches them.
// content.json (stories, guides, collections, surah introductions) is maintained directly in iqra_app/assets/data/.
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const data = path.join(root, 'data');
const out = path.join(root, 'iqra_app', 'assets');
const read = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const write = (p, v) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, typeof v === 'string' ? v : JSON.stringify(v)); };
const size = (p) => (fs.statSync(p).size / 1e6).toFixed(1) + ' MB';

const quran = path.join(out, 'data', 'quran.json');
write(quran, fs.readFileSync(path.join(data, 'quran.json'), 'utf8'));

const pages = [];
for (let p = 1; p <= 604; p++) pages.push(read(path.join(data, 'pages', `${p}.json`)));
write(path.join(out, 'data', 'pages.json'), pages);

const words = [];
for (let s = 1; s <= 114; s++) words.push(read(path.join(data, 'words', `${s}.json`)));
write(path.join(out, 'data', 'words.json'), words);

for (const f of fs.readdirSync(path.join(data, 'discover'))) {
  write(path.join(out, 'data', 'discover', f), fs.readFileSync(path.join(data, 'discover', f), 'utf8'));
}

const qcfDir = path.join(data, 'qcf');
if (fs.existsSync(qcfDir)) {
  const qcf = [];
  for (let p = 1; p <= 604; p++) qcf.push(read(path.join(qcfDir, `${p}.json`)));
  write(path.join(out, 'qcf', 'qcf.json'), qcf);
  console.log('qcf.json', size(path.join(out, 'qcf', 'qcf.json')));
}

console.log('quran.json', size(quran), '| pages.json', size(path.join(out, 'data', 'pages.json')), '| words.json', size(path.join(out, 'data', 'words.json')));
