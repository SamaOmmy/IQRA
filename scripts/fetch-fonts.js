// Optional: downloads the authentic Madani mushaf fonts into src/fonts/mushaf/ (git-ignored).
//   node scripts/fetch-fonts.js
// These fonts belong to the King Fahd Glorious Qur'an Printing Complex and are distributed via Quran Foundation.
// Their terms allow bundling them in an app but not offering them separately, so they are never committed to this
// repository. Read NOTICE.md and https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/ before you
// distribute a build that includes them. Without them IQRA falls back to the open Scheherazade New font.
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'src', 'fonts', 'mushaf');
const BASE = 'https://verses.quran.foundation/fonts/quran/hafs';
fs.mkdirSync(OUT, { recursive: true });

const files = [{ name: 'UthmanicHafs.woff2', url: `${BASE}/uthmanic_hafs/UthmanicHafs1Ver18.woff2` }];
for (let p = 1; p <= 604; p++) files.push({ name: `p${p}.woff2`, url: `${BASE}/v2/woff2/p${p}.woff2` });

async function download({ name, url }) {
  const dest = path.join(OUT, name);
  if (fs.existsSync(dest)) return false;
  for (let attempt = 1; ; attempt++) {
    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      fs.writeFileSync(dest, Buffer.from(await res.arrayBuffer()));
      return true;
    } catch (err) {
      if (attempt >= 4) throw new Error(`${url}: ${err.message}`);
      await new Promise((r) => setTimeout(r, 600 * attempt));
    }
  }
}

(async () => {
  let next = 0, done = 0, fetched = 0;
  const failed = [];
  await Promise.all(Array.from({ length: 8 }, async () => {
    while (next < files.length) {
      const f = files[next++];
      try { if (await download(f)) fetched++; } catch (e) { failed.push(e.message); }
      if (++done % 50 === 0 || done === files.length) process.stdout.write(`\rfonts: ${done}/${files.length}  `);
    }
  }));
  console.log(`\n${fetched} downloaded, ${files.length - fetched - failed.length} already present, ${failed.length} failed`);
  failed.forEach((f) => console.log('  FAILED', f));
  process.exit(failed.length ? 1 : 0);
})();
