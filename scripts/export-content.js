'use strict';
// Exports the authored content (stories, collections, guides, surah introductions...) that lives in src/*.js as plain JSON
// so the Flutter app can bundle it:  node scripts/export-content.js  ->  iqra_app/assets/data/content.json
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.join(__dirname, '..');
const order = [
  'discover-content', 'stories-quran', 'stories-sira', 'collections-more', 'stories-more', 'stories-told', 'stories-women',
  'stories-scholars', 'stories-history', 'stories-moments', 'deep-sira-1', 'deep-sira-2', 'deep-prophets', 'deep-tales',
  'deep-companions', 'guides', 'surah-guide',
];

const ctx = vm.createContext({ console });
for (const f of order) {
  const file = path.join(root, 'src', f + '.js');
  vm.runInContext(fs.readFileSync(file, 'utf8'), ctx, { filename: file });
}
const out = vm.runInContext('JSON.stringify({ discover: DISCOVER, guides: GUIDES, surahIntros: SURAH_INTROS })', ctx);
const dest = path.join(root, 'iqra_app', 'assets', 'data', 'content.json');
fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.writeFileSync(dest, out);

const c = JSON.parse(out);
console.log('stories', c.discover.stories.length, 'deep', Object.keys(c.discover.deep).length, 'shelves', c.discover.shelves.length,
  'collections', c.discover.collections.length, 'guides', c.guides.length, 'surahIntros', Object.keys(c.surahIntros).length,
  'bytes', out.length);
console.log('keys', Object.keys(c.discover).join(','));
