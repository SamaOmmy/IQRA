'use strict';
// Navigation: the slide-over drawer (library, search, saved verses, offline audio) and the Ctrl+K command palette.

const drawerEl = $('#drawer');
const DRAWER_TITLES = { library: 'Library', search: 'Search', saved: 'Saved verses', offline: 'Offline audio' };
let drawerPanel = null;

function openDrawer(name) {
  drawerPanel = name;
  drawerEl.hidden = false;
  $('#drawer-title').textContent = DRAWER_TITLES[name];
  $$('.panel', drawerEl).forEach((p) => p.classList.toggle('active', p.id === `panel-${name}`));
  $$('.rail-btn[data-drawer]').forEach((b) => b.classList.toggle('active', b.dataset.drawer === name));
  if (name === 'library') { renderSurahList(); markActiveSurah(); }
  if (name === 'saved') renderSaved();
  if (name === 'offline') refreshOffline();
  if (name === 'search') { const i = $('#search-input'); i.focus(); i.select(); }
}

function closeDrawer() {
  drawerPanel = null;
  drawerEl.hidden = true;
  $$('.rail-btn[data-drawer]').forEach((b) => b.classList.remove('active'));
}

function toggleDrawer(name) {
  if (drawerPanel === name && !drawerEl.hidden) closeDrawer(); else openDrawer(name);
}

// ---------- Library ----------
function renderSurahList() {
  const q = $('#surah-filter').value.trim().toLowerCase();
  const items = S.filter((s) => !q
    || String(s.n) === q || s.en.toLowerCase().includes(q) || s.meaning.toLowerCase().includes(q) || s.ar.includes(q));
  $('#surah-list').innerHTML = items.length
    ? items.map((s) => `
      <li data-surah="${s.n}" class="${s.n === state.surah ? 'active' : ''}">
        <div class="num"><span>${s.n}</span></div>
        <div class="names">
          <div class="name">${esc(s.en)}</div>
          <div class="sub">${esc(s.meaning)} · ${s.ayahs.length} verses · p. ${s.ayahs[0].page}</div>
        </div>
        <div class="ar">${esc(s.ar)}</div>
      </li>`).join('')
    : '<li class="empty">No surahs match.</li>';
}

function markActiveSurah() {
  $$('#surah-list li').forEach((li) => li.classList.toggle('active', +li.dataset.surah === state.surah));
  if (drawerPanel === 'library') {
    const active = $('#surah-list li.active');
    if (active) active.scrollIntoView({ block: 'nearest' });
  }
}

function renderJuzList() {
  const starts = [];
  for (const s of S) for (const a of s.ayahs) if (!starts[a.juz]) starts[a.juz] = { s: s.n, a: a.n, page: a.page };
  $('#juz-list').innerHTML = starts.map((p, juz) => !p ? '' : `
    <li data-surah="${p.s}" data-ayah="${p.a}">
      <div class="num"><span>${juz}</span></div>
      <div class="names">
        <div class="name">Juz ${juz}</div>
        <div class="sub">${esc(surahOf(p.s).en)} ${p.s}:${p.a} · p. ${p.page}</div>
      </div>
    </li>`).join('');
}

$$('[data-lib]').forEach((b) => b.addEventListener('click', () => {
  const juz = b.dataset.lib === 'juz';
  $$('[data-lib]').forEach((t) => t.classList.toggle('active', t === b));
  $('#surah-list').hidden = juz;
  $('#surah-filter').hidden = juz;
  $('#juz-list').hidden = !juz;
}));
$('#surah-filter').addEventListener('input', renderSurahList);

// ---------- Saved ----------
function renderSaved() {
  const list = $('#saved-list');
  if (!state.bookmarks.length) {
    list.innerHTML = '<li class="empty">No saved verses yet. Select a verse and press B.</li>';
    return;
  }
  list.innerHTML = state.bookmarks.map((b) => {
    const text = translationText(state.tr1, b.s, b.a);
    return `<li class="result-item" data-surah="${b.s}" data-ayah="${b.a}">
      <span class="ref">${esc(surahOf(b.s).en)} ${b.s}:${b.a}</span>
      <span class="snippet" dir="${isRtlTranslation(state.tr1) ? 'rtl' : 'ltr'}">${esc(text.length > 110 ? text.slice(0, 110) + '…' : text)}</span>
    </li>`;
  }).join('');
}

// ---------- Search ----------
// Covers the Arabic text and the translation currently selected.
let searchIndex = null;
let searchIndexTr = null;
function buildSearchIndex() {
  searchIndexTr = state.tr1;
  searchIndex = [];
  for (const s of S) for (const a of s.ayahs) {
    searchIndex.push({ s: s.n, a: a.n, ar: normalizeArabic(a.a), t: translationText(state.tr1, s.n, a.n).toLowerCase() });
  }
}

function findVerses(raw, limit) {
  if (!searchIndex || searchIndexTr !== state.tr1) buildSearchIndex();
  const isArabic = /[؀-ۿ]/.test(raw);
  const q = isArabic ? normalizeArabic(raw) : raw.toLowerCase();
  if (q.length < 2) return { hits: [], isArabic, q };
  const hits = [];
  for (const e of searchIndex) {
    if ((isArabic ? e.ar : e.t).includes(q)) {
      hits.push(e);
      if (hits.length >= limit) break;
    }
  }
  return { hits, isArabic, q };
}

function highlight(text, q) {
  const i = text.toLowerCase().indexOf(q);
  if (i < 0) return esc(text);
  return esc(text.slice(0, i)) + '<mark>' + esc(text.slice(i, i + q.length)) + '</mark>' + esc(text.slice(i + q.length));
}

function runSearch() {
  const raw = $('#search-input').value.trim();
  const out = $('#search-results');
  if (!raw) { out.innerHTML = '<li class="empty">Type a word in Arabic or in the selected translation. To jump somewhere, press Ctrl+K.</li>'; return; }
  const { hits, isArabic, q } = findVerses(raw, 200);
  if (q.length < 2) { out.innerHTML = '<li class="empty">Keep typing…</li>'; return; }
  if (!hits.length) { out.innerHTML = '<li class="empty">No results.</li>'; return; }
  const dir = isRtlTranslation(state.tr1) ? 'rtl' : 'ltr';
  out.innerHTML = hits.map((e) => {
    const tr = translationText(state.tr1, e.s, e.a);
    const body = isArabic
      ? `<span class="snippet snippet-ar">${esc(ayahOf(e.s, e.a).a)}</span><span class="snippet" dir="${dir}">${esc(tr)}</span>`
      : `<span class="snippet" dir="${dir}">${highlight(tr, q)}</span>`;
    return `<li class="result-item" data-surah="${e.s}" data-ayah="${e.a}"><span class="ref">${esc(surahOf(e.s).en)} ${e.s}:${e.a}</span>${body}</li>`;
  }).join('') + (hits.length >= 200 ? '<li class="empty">Showing the first 200 results.</li>' : '');
}
$('#search-input').addEventListener('input', runSearch);

// Lists in the drawer share one handler: any <li> with data-surah navigates.
drawerEl.addEventListener('click', (e) => {
  const li = e.target.closest('li[data-surah]');
  if (!li) return;
  navigateTo(+li.dataset.surah, +(li.dataset.ayah || 1));
  closeDrawer();
});

document.addEventListener('mousedown', (e) => {
  if (!drawerEl.hidden && !drawerEl.contains(e.target) && !$('#rail').contains(e.target)) closeDrawer();
});
$$('.rail-btn[data-drawer]').forEach((b) => b.addEventListener('click', () => toggleDrawer(b.dataset.drawer)));
$('#drawer-close').addEventListener('click', closeDrawer);

// ---------- Command palette ----------
const paletteWrap = $('#palette-wrap');
const paletteInput = $('#palette-input');
const paletteList = $('#palette-list');
let paletteItems = [];
let paletteIndex = 0;

const goVerse = (s, a) => () => navigateTo(s, a);
const POPULAR = [[1, 1, 'Al-Fatiha'], [2, 255, 'Ayat al-Kursi'], [18, 1, 'Al-Kahf'], [36, 1, 'Ya-Sin'], [55, 1, 'Ar-Rahman'], [67, 1, 'Al-Mulk']];

function buildPaletteItems(raw) {
  const q = raw.trim();
  const items = [];
  const verseItem = (s, a, title) => ({
    title: title || `${surahOf(s).en} ${s}:${a}`,
    sub: translationText(state.tr1, s, a).slice(0, 90),
    run: goVerse(s, a),
  });

  if (!q) {
    items.push({ title: `Continue: ${surahOf(current.s).en} ${current.s}:${current.a}`, sub: `Page ${pageOf(current.s, current.a)}`, run: goVerse(current.s, current.a) });
    for (const [s, a, name] of POPULAR) items.push({ title: name, sub: `${s}:${a}`, run: goVerse(s, a) });
    return items;
  }

  let m;
  if ((m = q.match(/^(\d{1,3})\s*[:.]\s*(\d{1,3})$/))) {
    const s = +m[1], a = +m[2];
    if (s >= 1 && s <= 114 && a >= 1 && a <= surahOf(s).ayahs.length) items.push(verseItem(s, a));
    return items;
  }
  if ((m = q.match(/^(?:p(?:age)?\.?\s*|#)(\d{1,3})$/i))) {
    const p = +m[1];
    if (p >= 1 && p <= MAX_PAGE) { const v = firstVerseOfPage(p); items.push({ title: `Page ${p}`, sub: `${surahOf(v.s).en} ${v.s}:${v.a}`, run: () => navigateTo(v.s, v.a, { page: p }) }); }
    return items;
  }
  if ((m = q.match(/^j(?:uz)?\.?\s*(\d{1,2})$/i))) {
    const j = +m[1];
    for (const s of S) {
      const a = s.ayahs.find((x) => x.juz === j);
      if (a) { items.push({ title: `Juz ${j}`, sub: `${s.en} ${s.n}:${a.n} · page ${a.page}`, run: goVerse(s.n, a.n) }); break; }
    }
    return items;
  }

  const key = q.toLowerCase().replace(/[^a-z]/g, '');
  const arKey = normalizeArabic(q);
  const surahs = S.filter((s) => String(s.n) === q
    || (key.length >= 2 && (s.en.toLowerCase().replace(/[^a-z]/g, '').includes(key) || s.meaning.toLowerCase().replace(/[^a-z]/g, '').includes(key)))
    || (/[؀-ۿ]/.test(q) && normalizeArabic(s.ar).includes(arKey)));
  for (const s of surahs.slice(0, 6)) items.push({ title: `${s.n}. ${s.en}`, sub: `${s.meaning} · ${s.ayahs.length} verses · page ${s.ayahs[0].page}`, run: goVerse(s.n, 1) });

  if (q.length >= 3) {
    const { hits } = findVerses(q, 5);
    for (const h of hits) items.push(verseItem(h.s, h.a));
    items.push({ title: `Search all verses for “${q}”`, sub: 'Open the search panel', run: () => { openDrawer('search'); $('#search-input').value = q; runSearch(); } });
  }
  return items;
}

function renderPalette() {
  paletteItems = buildPaletteItems(paletteInput.value);
  paletteIndex = Math.min(paletteIndex, Math.max(0, paletteItems.length - 1));
  paletteList.innerHTML = paletteItems.length
    ? paletteItems.map((it, i) => `<li data-i="${i}" class="${i === paletteIndex ? 'active' : ''}"><span class="p-title">${esc(it.title)}</span><span class="p-sub">${esc(it.sub || '')}</span></li>`).join('')
    : '<li class="empty">Nothing found. Try 2:255, “page 50”, “juz 3” or a surah name.</li>';
}

function openPalette(prefill = '') {
  paletteWrap.hidden = false;
  paletteInput.value = prefill;
  paletteIndex = 0;
  renderPalette();
  paletteInput.focus();
}
function closePalette() { paletteWrap.hidden = true; }

function runPaletteItem(i) {
  const it = paletteItems[i];
  if (!it) return;
  closePalette();
  it.run();
}

paletteInput.addEventListener('input', () => { paletteIndex = 0; renderPalette(); });
paletteInput.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
    e.preventDefault();
    if (!paletteItems.length) return;
    paletteIndex = (paletteIndex + (e.key === 'ArrowDown' ? 1 : -1) + paletteItems.length) % paletteItems.length;
    renderPalette();
    $('#palette-list li.active')?.scrollIntoView({ block: 'nearest' });
  } else if (e.key === 'Enter') {
    e.preventDefault();
    runPaletteItem(paletteIndex);
  }
});
paletteList.addEventListener('click', (e) => {
  const li = e.target.closest('li[data-i]');
  if (li) runPaletteItem(+li.dataset.i);
});
paletteWrap.addEventListener('mousedown', (e) => { if (e.target === paletteWrap) closePalette(); });
$('#loc').addEventListener('click', () => openPalette());
