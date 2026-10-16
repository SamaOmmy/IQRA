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

// The source text carries the narrator's chain, the compiler's references ("[رَوَاهُ ...]", "حديث حسن ...") and <br> tags: keep the hadith itself.
const DIA = '[\u064B-\u0652\u0670]*';
const loose = (w) => new RegExp([...w].map((ch) => ch + DIA).join(''));
const TAIL = [loose('رَوَاهُ'), loose('رَوَيْنَاهُ'), loose('حَدِيثٌ حَسَنٌ'), loose('حديث حسن'), loose('وَاَلتِّرْمِذِيُّ'), /،\s*،/, /\sبهذا اللفظ/];
function cleanNawawi(n, raw) {
  let t = String(raw).replace(/<br\s*\/?>/g, ' ').replace(/[‎‏‪-‮]/g, '');
  // references in square brackets (not the words the Prophet's addition "[ يشهد أن لا إله إلا الله ... ]" in hadith 14)
  t = t.replace(/\[[^\]]*\]/g, (m) => (/رَوَاهُ|رواه|رقم|وَمُسْلِمٌ|الْبُخَارِيُّ|وَالنَّسَائِيّ|السنن|راجع|سورة|\d\/\d/.test(m) ? ' ' : m));
  if (n === 19) t = t.replace(new RegExp(loose('رَوَاهُ التِّرْمِذِيُّ').source + '[^.]*\.'), ' ');
  if (n === 27) t = t.replace(new RegExp(loose('رَوَاهُ مُسْلِمٌ').source + '\s*\.?'), ' ');
  let cut = t.length;
  for (const re of TAIL) {
    const m = re.exec(t);
    if (m && m.index > 40 && m.index < cut) cut = m.index;
  }
  t = t.slice(0, cut).replace(/\s+/g, ' ').replace(/\s+([.،:])/g, '$1').trim();
  // straight quotation marks around the Prophet's words become Arabic quotation marks
  let depth = 0;
  t = t.replace(/\s*"\s*/g, (m, at) => {
    const opens = depth === 0 || /[:،(]\s*$/.test(t.slice(0, at));
    depth += opens ? 1 : -1;
    return opens ? ' «' : '» ';
  });
  return t.replace(/\s+/g, ' ').replace(/\s+([.،:؟])/g, '$1').replace(/[\s،]+$/, '').trim();
}
const nawawi = read('nawawi-ar.json').hadiths.map((h) => ({ n: h.hadithnumber, ar: cleanNawawi(h.hadithnumber, h.text) }));
if (nawawi.length < 40) throw new Error('Expected the Forty Hadith');
const nFiles = fs.readdirSync(__dirname).filter((f) => /^nawawi-explain-\d+\.js$/.test(f)).sort();
const nExplain = Object.assign({}, ...nFiles.map((f) => require('./' + f)));
for (const h of nawawi) if (nExplain[h.n]) h.x = nExplain[h.n];
const tFiles = fs.readdirSync(__dirname).filter((f) => /^nawawi-translate-\d+\.js$/.test(f)).sort();
const nTranslate = Object.assign({}, ...tFiles.map((f) => require('./' + f)));
for (const h of nawawi) if (nTranslate[h.n]) h.en = nTranslate[h.n];
const missing = nawawi.filter((h) => !h.en).map((h) => h.n);
if (missing.length) throw new Error('Forty Hadith without a translation: ' + missing.join(', '));
console.log(`Forty Hadith explanations: ${nawawi.filter((h) => h.x).length} of ${nawawi.length}`);
write('discover/nawawi.json', nawawi);

console.log(`Discover: ${hisn.length} Hisn categories (${hisn.reduce((n, c) => n + c.items.length, 0)} adhkar), ${azkar.length} morning/evening adhkar, ${nawawi.length} hadith`);

// ---- Hadith library: Arabic from the classical collections, checked against the curated phrase ----
const curationFiles = ['hadith-curation.js', ...fs.readdirSync(__dirname).filter((f) => /^hadith-curation-\d+\.js$/.test(f)).sort()];
const curated = curationFiles.flatMap((f) => require('./' + f));
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
    if (/[،؛؟.,:;!]/.test(ch)) continue; // punctuation does not take part in matching
    if (/\s/.test(ch) && (out === '' || out.endsWith(' '))) continue;
    out += /\s/.test(ch) ? ' ' : strip(ch);
    map.push(i);
  }
  return { out, map };
}
function matnOf(text, c) {
  if (c.from) {
    const { out, map } = stripMap(text);
    const a = out.indexOf(strip(c.from).replace(/\s+/g, ' '));
    if (a < 0) throw new Error(c.id + ': "from" phrase not found');
    const toKey = strip(c.to || c.from).replace(/\s+/g, ' ');
    const z = out.indexOf(toKey, a);
    if (z < 0) throw new Error(c.id + ': "to" phrase not found');
    let end = map[z + toKey.length - 1] + 1;
    while (/[ً-ٰٟۖ-ۭ]/.test(text[end] || '')) end++; // keep the vowel marks on the last letter
    return text.slice(map[a], end).replace(/\s+/g, ' ').trim();
  }
  // the quoted words of the Prophet: the first quotation that holds the expected phrase (a narration can quote more than one speaker)
  const quotes = [...text.matchAll(/‏\s*"\s*‏\s*([\s\S]*?)\s*‏?\s*"\s*‏?/g)].map((x) => x[1]);
  const flat = (t) => strip(t).replace(/[،؛؟.,:;!"']/g, ' ').replace(/\s+/g, ' ').trim();
  const m = quotes.find((q) => flat(q).includes(flat(c.phrase))) ?? quotes[0];
  return (m ?? text).replace(/[‎‏]/g, '').replace(/\s+/g, ' ').replace(/\s*\.\s*$/, '').trim();
}
const seen = new Set();
const problems = [];
const hadith = curated.map((c) => {
  if (seen.has(c.id)) throw new Error('duplicate hadith id ' + c.id);
  seen.add(c.id);
  const raw = collection(c.book).get(c.n);
  if (!raw) { problems.push(`${c.id}: no hadith ${c.n} in ${c.book}`); return { id: c.id, theme: c.theme, title: c.title, en: c.en, src: c.src, ar: '' }; }
  let matn;
  try { matn = matnOf(raw, c); } catch (e) { problems.push(e.message); matn = ''; }
  const norm = (t) => strip(t).replace(/[،؛؟.,:;!"']/g, ' ').replace(/\s+/g, ' ').trim();
  if (matn && !norm(matn).includes(norm(c.phrase))) problems.push(`${c.id}: Arabic text of ${c.book} ${c.n} does not contain the expected phrase`);
  // the source text carries direction marks and quote marks around the Prophet's words; the app shows plain text
  const tidy = (t) => t.replace(/[‎‏]/g, '').replace(/\s*"\s*/g, ' ').replace(/\s+\./g, '.').replace(/\s+/g, ' ').trim();
  return { id: c.id, theme: c.theme, title: c.title, en: c.en, src: c.src, ar: tidy(matn) };
});
if (problems.length) throw new Error(['Hadith that do not match their source:', ...problems].join('\n  '));
// In-depth explanations (scripts/hadith-explain-N.js): { id: { s: setting[], m: meaning[], l: lessons[] } }
const explainFiles = fs.readdirSync(__dirname).filter((f) => /^hadith-explain-\d+\.js$/.test(f)).sort();
const explain = Object.assign({}, ...explainFiles.map((f) => require('./' + f)));
const known = new Set(hadith.map((h) => h.id));
for (const id of Object.keys(explain)) if (!known.has(id)) throw new Error('explanation for unknown hadith id: ' + id);
for (const h of hadith) if (explain[h.id]) h.x = explain[h.id];
const trFiles = fs.readdirSync(__dirname).filter((f) => /^hadith-translate-\d+\.js$/.test(f)).sort();
const translate = Object.assign({}, ...trFiles.map((f) => require('./' + f)));
for (const id of Object.keys(translate)) if (!known.has(id)) throw new Error('translation for unknown hadith id: ' + id);
for (const h of hadith) if (translate[h.id]) h.en = translate[h.id];
console.log(`Hadith explanations: ${hadith.filter((h) => h.x).length} of ${hadith.length}`);
write('discover/hadith.json', hadith);
console.log(`Hadith library: ${hadith.length} hadith, all matched against their sources`);
