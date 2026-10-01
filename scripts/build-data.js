// Turns the raw downloads in data/raw/ into the compact files the app loads:
//   data/quran.json              surahs, verses, default translation, manifests
//   data/translations/<id>.json  one string per verse (global verse order)
//   data/words/<surah>.json      word-by-word per verse: [uthmani, meaning, transliteration, qpc-hafs]
//   data/pages/<page>.json       Madani mushaf page layout (words with line numbers, QCF V2 layout)
//   data/qcf/<page>.json         QCF V2 glyph strings aligned with pages/<page>.json (git-ignored, see NOTICE.md)
//   data/tafsir/<id>/<surah>.json  one entry per verse (string, or a number pointing at the verse that holds a shared text)
const fs = require('fs');
const path = require('path');
const config = require('./data-config');

const DATA = path.join(__dirname, '..', 'data');
const RAW = path.join(DATA, 'raw');
const readRaw = (...p) => JSON.parse(fs.readFileSync(path.join(RAW, ...p), 'utf8'));
const write = (rel, obj) => {
  const file = path.join(DATA, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(obj));
};
const clean = (s) => String(s ?? '').replace(/^﻿/, '').trim();

const arSurahs = readRaw('ar.json').data.surahs;
const enSurahs = readRaw('en.sahih.json').data.surahs;

// ---- Words / pages -------------------------------------------------------
const pages = Array.from({ length: 605 }, () => []);
const qcf = Array.from({ length: 605 }, () => []);
const wordsBySurah = [];
const versePage = {}; // "s:a" -> first page of the verse
const wordTypes = new Set();

for (let n = 1; n <= 114; n++) {
  const verses = readRaw('words-v2', `${n}.json`).verses;
  if (verses.length !== arSurahs[n - 1].ayahs.length) throw new Error(`Surah ${n}: word data has ${verses.length} verses`);
  wordsBySurah[n] = verses.map((v) => {
    const a = +v.verse_key.split(':')[1];
    const list = [];
    v.words.forEach((w) => {
      wordTypes.add(w.char_type_name);
      const isEnd = w.char_type_name === 'end';
      const text = clean(w.text_uthmani);
      if (!versePage[`${n}:${a}`]) versePage[`${n}:${a}`] = w.page_number;
      pages[w.page_number].push([n, a, text, w.line_number, (isEnd ? 1 : 0) | (w.position === 1 ? 2 : 0)]);
      qcf[w.page_number].push(w.code_v2 || '');
      if (!isEnd) list.push([text, clean(w.translation?.text), clean(w.transliteration?.text), clean(w.text_qpc_hafs)]);
    });
    return list;
  });
}
console.log('word char types:', [...wordTypes].join(', '));

let pageCount = 0;
for (let p = 1; p <= 604; p++) {
  if (!pages[p].length) throw new Error(`Page ${p} has no words`);
  write(`pages/${p}.json`, pages[p]);
  write(`qcf/${p}.json`, qcf[p]);
  pageCount++;
}
for (let n = 1; n <= 114; n++) write(`words/${n}.json`, wordsBySurah[n]);

// ---- Core text -----------------------------------------------------------
let pageMismatch = 0;
const surahs = arSurahs.map((s, i) => ({
  n: s.number,
  ar: clean(s.name).replace(/^سُورَةُ\s*/, ''),
  en: s.englishName,
  meaning: s.englishNameTranslation,
  type: s.revelationType,
  ayahs: s.ayahs.map((a, j) => {
    let text = clean(a.text);
    // The source prepends the Bismillah to verse 1 of every surah except Al-Fatiha (where it is verse 1) and At-Tawbah.
    // Diacritic order differs from Al-Fatiha's copy, so strip by word count (4 words) rather than exact match.
    if (j === 0 && s.number !== 1 && s.number !== 9) text = text.split(' ').slice(4).join(' ');
    const page = versePage[`${s.number}:${a.numberInSurah}`];
    if (page !== a.page) pageMismatch++;
    return {
      n: a.numberInSurah,
      g: a.number,
      a: text,
      t: clean(enSurahs[i].ayahs[j].text),
      juz: a.juz,
      page,
      sajda: !!a.sajda,
    };
  }),
}));
console.log(`verse start pages differing from alquran.cloud: ${pageMismatch}`);

// ---- Translations --------------------------------------------------------
const editions = readRaw('editions.json').data;
const editionName = (id) => editions.find((e) => e.identifier === id)?.englishName ?? id;
const translationIds = [...config.translations, config.transliteration];
const translations = [{ id: 'en.sahih', name: 'Saheeh International', lang: 'en' }];

for (const id of translationIds) {
  const flat = readRaw('translations', `${id}.json`).data.surahs.flatMap((s) => s.ayahs.map((a) => clean(a.text)));
  if (flat.length !== 6236) throw new Error(`${id}: expected 6236 verses, got ${flat.length}`);
  write(`translations/${id}.json`, flat);
  if (id !== config.transliteration) translations.push({ id, name: editionName(id), lang: id.split('.')[0] });
}

// ---- Tafsir --------------------------------------------------------------
let tafsirBytes = 0;
for (const t of config.tafsirs) {
  for (let n = 1; n <= 114; n++) {
    const raw = readRaw('tafsir', t.id, `${n}.json`);
    const items = (Array.isArray(raw) ? raw : raw.ayahs).slice().sort((a, b) => a.ayah - b.ayah);
    const count = surahs[n - 1].ayahs.length;
    const out = new Array(count).fill('');
    const owner = new Map(); // text -> first verse that holds it
    for (const it of items) {
      const text = clean(it.text).replace(/\r/g, '');
      if (!text || it.ayah < 1 || it.ayah > count) continue;
      if (owner.has(text)) out[it.ayah - 1] = owner.get(text);
      else { owner.set(text, it.ayah); out[it.ayah - 1] = text; }
    }
    const json = JSON.stringify(out);
    tafsirBytes += json.length;
    write(`tafsir/${t.id}/${n}.json`, out);
  }
}

write('quran.json', {
  bismillah: surahs[0].ayahs[0].a,
  translations,
  tafsirs: config.tafsirs,
  surahs,
});

console.log(`Wrote ${surahs.length} surahs, ${pageCount} pages, ${translations.length} translations, ${config.tafsirs.length} tafsirs (${(tafsirBytes / 1e6).toFixed(1)} MB)`);
