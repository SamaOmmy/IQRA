'use strict';
// Shared state and helpers. All scripts are classic <script>s, so top-level declarations here are visible to the others.

const Q = window.api.loadQuran();
const S = Q.surahs;
const MUSHAF = window.api.mushaf(); // { qcf, hafs }: which authentic fonts are installed (both optional)

const RECITERS = [
  ['Alafasy_128kbps', 'Mishary Alafasy'],
  ['Abdul_Basit_Murattal_192kbps', 'Abdul Basit (Murattal)'],
  ['Abdul_Basit_Mujawwad_128kbps', 'Abdul Basit (Mujawwad)'],
  ['Husary_128kbps', 'Mahmoud Khalil Al-Husary'],
  ['Husary_Muallim_128kbps', 'Al-Husary (teaching, with repeats)'],
  ['Minshawy_Murattal_128kbps', 'Mohamed Al-Minshawi (Murattal)'],
  ['Minshawy_Mujawwad_192kbps', 'Mohamed Al-Minshawi (Mujawwad)'],
  ['Abdurrahmaan_As-Sudais_192kbps', 'Abdurrahman As-Sudais'],
  ['Saood_ash-Shuraym_128kbps', 'Saud Ash-Shuraim'],
  ['Maher_AlMuaiqly_64kbps', 'Maher Al-Muaiqly'],
  ['Abdullah_Basfar_192kbps', 'Abdullah Basfar'],
  ['Hudhaify_128kbps', 'Ali Al-Hudhaify'],
  ['Muhammad_Ayyoub_128kbps', 'Muhammad Ayyub'],
  ['Muhammad_Jibreel_128kbps', 'Muhammad Jibreel'],
  ['Ghamadi_40kbps', 'Saad Al-Ghamdi'],
  ['Abu_Bakr_Ash-Shaatree_128kbps', 'Abu Bakr Ash-Shatri'],
  ['Hani_Rifai_192kbps', 'Hani Ar-Rifai'],
  ['Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'Ahmed Al-Ajmi'],
  ['Yasser_Ad-Dussary_128kbps', 'Yasser Ad-Dosari'],
  ['Nasser_Alqatami_128kbps', 'Nasser Al-Qatami'],
  ['Salah_Al_Budair_128kbps', 'Salah Al-Budair'],
];
const THEMES = ['light', 'sepia', 'dark'];
const RTL_LANGS = new Set(['ar', 'fa', 'ur', 'ps', 'sd', 'ug', 'dv', 'ku']);
const STORE_KEY = 'iqra-state';

// ---------- State ----------
const defaults = {
  surah: 1, ayah: 1, page: 1, theme: 'light',
  view: 'mushaf', zoom: 1, spread: true, arSize: 30, trSize: 16,
  showTr: true, tr1: 'en.sahih', tr2: '', translit: false, wbw: false,
  reciter: RECITERS[0][0], speed: 1, continuous: true,
  tafsir: Q.tafsirs[0].id, studyOpen: false, studyTab: 'translation', bookmarks: [],
};
const state = { ...defaults, ...loadState() };
if (state.view !== 'mushaf' && state.view !== 'verses') state.view = state.view === 'pages' ? 'mushaf' : 'verses'; // names from v1
if (!Q.translations.some((t) => t.id === state.tr1)) state.tr1 = defaults.tr1;
if (state.tr2 && !Q.translations.some((t) => t.id === state.tr2)) state.tr2 = '';
if (!Q.tafsirs.some((t) => t.id === state.tafsir)) state.tafsir = defaults.tafsir;
if (!RECITERS.some(([id]) => id === state.reciter)) state.reciter = defaults.reciter;
if (!['translation', 'words', 'tafsir'].includes(state.studyTab)) state.studyTab = 'translation';

let current = { s: state.surah, a: state.ayah }; // the selected / playing verse

function loadState() {
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || {}; } catch { return {}; }
}
function save() {
  try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch { /* storage unavailable */ }
}

// ---------- DOM / text helpers ----------
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const toArabicDigits = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
const pad3 = (n) => String(n).padStart(3, '0');
const surahOf = (n) => S[n - 1];
const ayahOf = (s, a) => S[s - 1].ayahs[a - 1];
const pageOf = (s, a) => ayahOf(s, a).page;
const isBookmarked = (s, a) => state.bookmarks.some((b) => b.s === s && b.a === a);

const stage = $('#stage');
const reader = $('#reader');

let toastTimer;
function toast(msg) {
  const el = $('#toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
}

// Strip diacritics and unify letter variants so "الرحمن" matches "ٱلرَّحْمَٰنِ".
function normalizeArabic(s) {
  return s
    .replace(/[ً-ٰٟۖ-ۭ࣓-ࣿـ]/g, '')
    .replace(/[ٱآأإ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه');
}

// ---------- Lazy data (translations, word-by-word, pages, tafsir) ----------
const dataCache = new Map();
function data(rel) {
  if (!dataCache.has(rel)) dataCache.set(rel, window.api.loadData(rel));
  return dataCache.get(rel);
}

const translationMeta = (id) => Q.translations.find((t) => t.id === id);
const isRtlTranslation = (id) => RTL_LANGS.has(translationMeta(id)?.lang);

function translationText(id, s, a) {
  const verse = ayahOf(s, a);
  if (id === 'en.sahih') return verse.t;
  try { return data(`translations/${id}.json`)[verse.g - 1] || ''; } catch { return ''; }
}
function transliterationText(s, a) {
  try { return data('translations/en.transliteration.json')[ayahOf(s, a).g - 1] || ''; } catch { return ''; }
}
// Word entries: [uthmani, meaning, transliteration, qpc-hafs]
function wordsOf(s, a) {
  try { return data(`words/${s}.json`)[a - 1] || []; } catch { return []; }
}
// Arabic for a verse in the best script available: the KFGQPC Hafs text when its font is installed.
function arabicText(s, a) {
  if (MUSHAF.hafs) {
    const w = wordsOf(s, a);
    if (w.length) return w.map((x) => x[3] || x[0]).join(' ');
  }
  return ayahOf(s, a).a;
}

function firstVerseOfPage(p) {
  const w = data(`pages/${p}.json`)[0];
  return { s: w[0], a: w[1] };
}

// ---------- Fonts ----------
// Scheherazade New (open licence) is always bundled. The KFGQPC fonts are optional extras, see scripts/fetch-fonts.js.
const fontsReady = (async () => {
  const loads = [document.fonts.load('32px "Scheherazade New"', 'بسم')];
  if (MUSHAF.hafs) {
    const face = new FontFace('UthmanicHafs', 'url(fonts/mushaf/UthmanicHafs.woff2)');
    loads.push(face.load().then((f) => { document.fonts.add(f); document.documentElement.classList.add('hafs'); }).catch(() => {}));
  }
  await Promise.all(loads);
})();
