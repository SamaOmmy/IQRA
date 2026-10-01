// Downloads all raw source data into data/raw/. Safe to re-run: files that already exist are skipped.
//   node scripts/fetch-data.js
const fs = require('fs');
const path = require('path');
const config = require('./data-config');

const RAW = path.join(__dirname, '..', 'data', 'raw');

async function getJSON(url, tries = 5) {
  for (let i = 1; ; i++) {
    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (err) {
      if (i >= tries) throw new Error(`${url}: ${err.message}`);
      await new Promise((r) => setTimeout(r, 800 * i));
    }
  }
}

async function cached(file, url, transform = (x) => x) {
  const target = path.join(RAW, file);
  if (fs.existsSync(target)) return false;
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, JSON.stringify(transform(await getJSON(url))));
  return true;
}

// Run async jobs with limited concurrency.
async function pool(jobs, limit, label) {
  let next = 0, done = 0, fetched = 0;
  const failed = [];
  await Promise.all(Array.from({ length: limit }, async () => {
    while (next < jobs.length) {
      const job = jobs[next++];
      try { if (await job.run()) fetched++; } catch (e) { failed.push(`${job.name}: ${e.message}`); }
      if (++done % 25 === 0 || done === jobs.length) process.stdout.write(`\r${label}: ${done}/${jobs.length}   `);
    }
  }));
  console.log(`\n${label}: ${fetched} downloaded, ${jobs.length - fetched - failed.length} cached, ${failed.length} failed`);
  failed.forEach((f) => console.log('  FAILED', f));
  return failed.length;
}

(async () => {
  let failures = 0;

  // Core Arabic text + Sahih International are fetched as before.
  await cached('ar.json', 'https://api.alquran.cloud/v1/quran/quran-uthmani');
  await cached('en.sahih.json', 'https://api.alquran.cloud/v1/quran/en.sahih');
  await cached('editions.json', 'https://api.alquran.cloud/v1/edition');

  const editionJobs = [...config.translations, config.transliteration].map((id) => ({
    name: id,
    run: () => cached(`translations/${id}.json`, `https://api.alquran.cloud/v1/quran/${id}`),
  }));
  failures += await pool(editionJobs, 4, 'translations');

  const wordJobs = Array.from({ length: 114 }, (_, i) => i + 1).map((n) => ({
    name: `words ${n}`,
    run: () => cached(
      `words-v2/${n}.json`,
      `https://api.quran.com/api/v4/verses/by_chapter/${n}?words=true&mushaf=1&word_fields=text_uthmani,text_qpc_hafs,code_v2,line_number,page_number&word_translation_language=en&per_page=300&fields=page_number`,
    ),
  }));
  failures += await pool(wordJobs, 4, 'word-by-word');

  await cached('tafsir-editions.json', 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/editions.json');
  const tafsirJobs = [];
  for (const t of config.tafsirs) {
    for (let n = 1; n <= 114; n++) {
      tafsirJobs.push({
        name: `${t.id} ${n}`,
        run: () => cached(`tafsir/${t.id}/${n}.json`, `https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/${t.id}/${n}.json`),
      });
    }
  }
  failures += await pool(tafsirJobs, 8, 'tafsir');

  if (failures) { console.log(`\n${failures} downloads failed; re-run to retry.`); process.exit(1); }
  console.log('\nAll raw data downloaded. Now run: npm run build-data');
})();
