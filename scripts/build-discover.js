// Builds the Discover data from the raw downloads in data/raw/discover/:
//   data/discover/hisn.json    Hisn al-Muslim: [{ ar, en, items: [{ ar, en, count, tl? }] }]  (same order as the source)
//   data/discover/azkar.json   Morning & evening adhkar: [{ order, ar, en, tl, count, countText, fadl, source, type }]
//   data/discover/nawawi.json  Arabic text of Nawawi's Forty Hadith: [{ n, ar }]
// Sources: YousefAsalya/Islamic-Pro-azkar-API (MIT), Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT),
// fawazahmed0/hadith-api (Unlicense; classical Arabic text). See NOTICE.md.
const fs = require('fs');
const path = require('path');

const DATA = path.join(__dirname, '..', 'data');
const read = (f) => JSON.parse(fs.readFileSync(path.join(DATA, 'raw', 'discover', f), 'utf8'));
const write = (rel, obj) => {
  const file = path.join(DATA, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(obj));
};

const balanced = (s) => (s.match(/\(/g) || []).length === (s.match(/\)/g) || []).length;
// The sources wrap most texts in parentheses, e.g. "((...))." or "(...)": remove the wrapper but keep inner brackets.
function clean(text) {
  let s = String(text ?? '').replace(/\s+/g, ' ').trim();
  for (let i = 0; i < 4; i++) {
    const m = s.match(/^\(\s*([\s\S]*?)\s*\)\s*\.?$/);
    if (m && balanced(m[1])) s = m[1].trim(); else break;
  }
  return s;
}

const hisnEn = read('hisn-en.json');
const hisnAr = read('hisn-ar.json');
if (hisnEn.length !== hisnAr.length) throw new Error('Hisn en/ar category counts differ');
const hisn = hisnEn.map((c, i) => {
  const a = hisnAr[i];
  if (a.id !== c.id || a.array.length !== c.array.length) throw new Error(`Hisn category ${i} does not line up between languages`);
  return {
    ar: String(a.category).trim(),
    en: String(c.category).replace(/\s+/g, ' ').trim().replace(/^./, (x) => x.toUpperCase()),
    items: c.array.map((it, j) => ({
      ar: clean(a.array[j].text),
      en: clean(it.text),
      count: it.count || 1,
      ...(it.transliteration ? { tl: clean(it.transliteration) } : {}),
    })),
  };
});
write('discover/hisn.json', hisn);

const azkar = read('azkar-en.json').map((x) => ({
  order: x.order,
  ar: String(x.content).trim(),
  en: String(x.translation).trim(),
  tl: String(x.transliteration || '').trim(),
  count: x.count,
  countText: x.count_description,
  fadl: String(x.fadl || '').trim(),
  source: String(x.source || '').trim(),
  type: x.type, // 0 morning and evening, 1 morning only, 2 evening only
}));
write('discover/azkar.json', azkar);

const nawawi = read('nawawi-ar.json').hadiths.map((h) => ({ n: h.hadithnumber, ar: String(h.text).replace(/\s+/g, ' ').trim() }));
if (nawawi.length < 40) throw new Error('Expected the Forty Hadith');
write('discover/nawawi.json', nawawi);

console.log(`Discover: ${hisn.length} Hisn categories (${hisn.reduce((n, c) => n + c.items.length, 0)} adhkar), ${azkar.length} morning/evening adhkar, ${nawawi.length} hadith`);

// ---- Hadith library: Arabic from the classical collections, checked against the curated phrase ----
const curated = require('./hadith-curation');
const strip = (s) => s.replace(/[ً-ٰٟۖ-ۭـ]/g, '').replace(/[آأإٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
const collections = {};
const collection = (book) => (collections[book] ||= new Map(read(`ara-${book}.json`).hadiths.map((h) => [h.hadithnumber, h.text])));
// The text is "chain of narrators, then the Prophet's words in quotation marks". Keep the quoted words, or, where an entry gives
// explicit "from" / "to" phrases, exactly the stretch between them (matched ignoring diacritics, cut from the original text).
function stripMap(s) {
  const map = [];
  let out = '';
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (/[ً-ٰٟۖ-ۭـ]/.test(ch)) continue;
    out += strip(ch);
    map.push(i);
  }
  return { out, map };
}
function matnOf(text, c) {
  if (c.from) {
    const { out, map } = stripMap(text);
    const a = out.indexOf(strip(c.from));
    if (a < 0) throw new Error(c.id + ': "from" phrase not found');
    const toKey = strip(c.to || c.from);
    const z = out.indexOf(toKey, a);
    if (z < 0) throw new Error(c.id + ': "to" phrase not found');
    return text.slice(map[a], map[z + toKey.length - 1] + 1).replace(/\s+/g, ' ').trim();
  }
  const m = text.match(/‏\s*"\s*‏\s*([\s\S]*?)\s*‏?\s*"\s*‏?/);
  return (m ? m[1] : text).replace(/[‎‏]/g, '').replace(/\s+/g, ' ').replace(/\s*\.\s*$/, '').trim();
}
const seen = new Set();
const hadith = curated.map((c) => {
  if (seen.has(c.id)) throw new Error('duplicate hadith id ' + c.id);
  seen.add(c.id);
  const raw = collection(c.book).get(c.n);
  if (!raw) throw new Error(`${c.id}: no hadith ${c.n} in ${c.book}`);
  const matn = matnOf(raw, c);
  if (!strip(matn).includes(strip(c.phrase))) throw new Error(`${c.id}: Arabic text of ${c.book} ${c.n} does not contain the expected phrase`);
  return { id: c.id, theme: c.theme, title: c.title, en: c.en, src: c.src, ar: matn };
});
write('discover/hadith.json', hadith);
console.log(`Hadith library: ${hadith.length} hadith, all matched against their sources`);
