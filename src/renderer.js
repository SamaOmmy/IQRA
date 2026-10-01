'use strict';
// Main UI: sidebar, reader views (verses / text / pages), display options, keyboard. Loaded last.

const reader = $('#reader');

// ---------- Sidebar ----------
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
          <div class="sub">${esc(s.meaning)} · ${s.ayahs.length} verses</div>
        </div>
        <div class="ar">${esc(s.ar)}</div>
      </li>`).join('')
    : '<li class="empty">No surahs match.</li>';
}

function markActiveSurah() {
  $$('#surah-list li').forEach((li) => li.classList.toggle('active', +li.dataset.surah === state.surah));
  const active = $('#surah-list li.active');
  if (active) active.scrollIntoView({ block: 'nearest' });
}

function renderJuzList() {
  const starts = [];
  for (const s of S) for (const a of s.ayahs) if (!starts[a.juz]) starts[a.juz] = { s: s.n, a: a.n };
  $('#juz-list').innerHTML = starts.map((p, juz) => !p ? '' : `
    <li data-surah="${p.s}" data-ayah="${p.a}">
      <div class="num"><span>${juz}</span></div>
      <div class="names">
        <div class="name">Juz ${juz}</div>
        <div class="sub">Starts at ${esc(surahOf(p.s).en)} ${p.s}:${p.a}</div>
      </div>
    </li>`).join('');
}

function renderSaved() {
  const list = $('#saved-list');
  if (!state.bookmarks.length) {
    list.innerHTML = '<li class="empty">No saved verses yet. Use ☆ on a verse, or press B.</li>';
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

// Search covers the Arabic text and the translation currently selected in Display.
let searchIndex = null;
let searchIndexTr = null;
function buildSearchIndex() {
  searchIndexTr = state.tr1;
  searchIndex = [];
  for (const s of S) for (const a of s.ayahs) {
    searchIndex.push({ s: s.n, a: a.n, ar: normalizeArabic(a.a), t: translationText(state.tr1, s.n, a.n).toLowerCase() });
  }
}

function highlight(text, q) {
  const i = text.toLowerCase().indexOf(q);
  if (i < 0) return esc(text);
  return esc(text.slice(0, i)) + '<mark>' + esc(text.slice(i, i + q.length)) + '</mark>' + esc(text.slice(i + q.length));
}

function runSearch() {
  const raw = $('#search-input').value.trim();
  const out = $('#search-results');
  if (!raw) { out.innerHTML = '<li class="empty">Type a word in Arabic or in the selected translation, or jump to a verse like 2:255.</li>'; return; }

  const ref = raw.match(/^(\d{1,3})\s*[:.\s]\s*(\d{1,3})$/);
  if (ref) {
    const s = +ref[1], a = +ref[2];
    if (s >= 1 && s <= 114 && a >= 1 && a <= surahOf(s).ayahs.length) {
      out.innerHTML = `<li class="result-item" data-surah="${s}" data-ayah="${a}">
        <span class="ref">Go to ${esc(surahOf(s).en)} ${s}:${a}</span>
        <span class="snippet">${esc(translationText(state.tr1, s, a))}</span></li>`;
    } else {
      out.innerHTML = '<li class="empty">That verse does not exist.</li>';
    }
    return;
  }

  if (!searchIndex || searchIndexTr !== state.tr1) buildSearchIndex();
  const isArabic = /[؀-ۿ]/.test(raw);
  const q = isArabic ? normalizeArabic(raw) : raw.toLowerCase();
  if (q.length < 2) { out.innerHTML = '<li class="empty">Keep typing…</li>'; return; }

  const hits = [];
  for (const e of searchIndex) {
    if ((isArabic ? e.ar : e.t).includes(q)) {
      hits.push(e);
      if (hits.length >= 200) break;
    }
  }
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

function switchTab(name) {
  $$('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
  $$('.panel').forEach((p) => p.classList.toggle('active', p.id === `panel-${name}`));
  if (name === 'saved') renderSaved();
  if (name === 'offline') refreshOffline();
  if (name === 'search') { $('#search-input').focus(); $('#search-input').select(); }
}

// ---------- Reader: verses and continuous text ----------
function arabicHtml(sn, v) {
  if (!state.wbw) return esc(v.a);
  const words = wordsOf(sn, v.n);
  if (!words.length) return esc(v.a);
  return '<div class="wbw" dir="rtl">' + words.map(([ar, tr, tl]) =>
    `<span class="wd"><span class="wd-ar">${esc(ar)}</span>${tl ? `<span class="wd-tl">${esc(tl)}</span>` : ''}<span class="wd-tr">${esc(tr)}</span></span>`).join('') + '</div>';
}

function translationsHtml(sn, a) {
  let out = '';
  if (state.translit) out += `<div class="translit">${esc(transliterationText(sn, a))}</div>`;
  const ids = [state.tr1, state.tr2].filter(Boolean);
  for (const id of ids) {
    out += `<div class="translation" dir="${isRtlTranslation(id) ? 'rtl' : 'ltr'}">`
      + (ids.length > 1 ? `<span class="tr-name">${esc(translationMeta(id).name)}</span>` : '')
      + `${esc(translationText(id, sn, a))}</div>`;
  }
  return out;
}

function renderSurahView() {
  const s = surahOf(state.surah);
  const showBismillah = s.n !== 1 && s.n !== 9;

  const head = `
    <div class="surah-head">
      <div class="ar-title">سورة ${esc(s.ar)}</div>
      <div class="en-title">${s.n}. ${esc(s.en)} — ${esc(s.meaning)}</div>
      <div class="meta">${s.type === 'Meccan' ? 'Meccan' : 'Medinan'} · ${s.ayahs.length} verses</div>
    </div>
    ${showBismillah ? `<div class="bismillah">${esc(Q.bismillah)}</div>` : ''}`;

  let body;
  if (state.view === 'flow') {
    body = `<div class="flow"><div class="arabic">${s.ayahs.map((a) =>
      `<span class="ayah" data-s="${s.n}" data-ayah="${a.n}">${esc(a.a)} <span class="mark">${toArabicDigits(a.n)}</span></span>`
    ).join(' ')}</div></div>`;
  } else {
    body = s.ayahs.map((a) => `
      <article class="verse" data-s="${s.n}" data-ayah="${a.n}">
        <div class="side">
          <div class="vnum">${a.n}</div>
          <button class="vbtn" data-act="play" title="Listen">▶</button>
          <button class="vbtn${isBookmarked(s.n, a.n) ? ' on' : ''}" data-act="bookmark" title="Save verse">${isBookmarked(s.n, a.n) ? '★' : '☆'}</button>
          <button class="vbtn" data-act="copy" title="Copy verse">⧉</button>
          <button class="vbtn" data-act="tafsir" title="Tafsir">📖</button>
        </div>
        <div class="body">
          <div class="arabic">${arabicHtml(s.n, a)}</div>
          ${translationsHtml(s.n, a.n)}
          ${a.sajda ? '<div class="sajda-tag">۩ Prostration verse</div>' : ''}
        </div>
      </article>`).join('');
  }

  const nav = `<div class="end-nav">
    ${s.n > 1 ? `<button class="btn" data-act="goto" data-surah="${s.n - 1}">‹ ${esc(surahOf(s.n - 1).en)}</button>` : '<span></span>'}
    ${s.n < 114 ? `<button class="btn" data-act="goto" data-surah="${s.n + 1}">${esc(surahOf(s.n + 1).en)} ›</button>` : '<span></span>'}
  </div>`;

  reader.innerHTML = `<div class="page${state.showTr ? '' : ' no-tr'}">${head}${body}${nav}</div>`;
  highlightCurrent();
}

function renderReader() {
  if (state.view === 'pages') renderPage(); else renderSurahView();
}

// Re-render in place (after a display option changes) without losing the scroll position.
function rerender() {
  const top = reader.scrollTop;
  renderReader();
  reader.scrollTop = top;
}

function applyPrefs() {
  const root = document.documentElement;
  root.dataset.theme = state.theme;
  root.style.setProperty('--ar-size', `${state.arSize}px`);
  root.style.setProperty('--tr-size', `${state.trSize}px`);
  for (const v of ['verse', 'flow', 'pages']) $(`#view-${v}`).classList.toggle('active', state.view === v);
  const pages = state.view === 'pages';
  $('#page-jump').hidden = !pages;
  $('#prev-surah').title = pages ? 'Previous page (Alt+Left)' : 'Previous surah (Alt+Left)';
  $('#next-surah').title = pages ? 'Next page (Alt+Right)' : 'Next surah (Alt+Right)';
  $('#chk-showtr').checked = state.showTr;
  $('#chk-translit').checked = state.translit;
  $('#chk-wbw').checked = state.wbw;
  $('#sel-tr1').value = state.tr1;
  $('#sel-tr2').value = state.tr2;
  $$('#theme-seg .seg-btn').forEach((b) => b.classList.toggle('active', b.dataset.theme === state.theme));
  $('#p-continuous').checked = state.continuous;
  $('#speed').value = String(state.speed);
  $('#reciter').value = state.reciter;
  $('#tafsir-toggle').classList.toggle('on', state.tafsirOpen);
  tafsirPanel.hidden = !state.tafsirOpen;
}

// ---------- Navigation ----------
function afterVerseChange() {
  state.ayah = current.a;
  state.surah = current.s;
  markActiveSurah();
  updateBookmarkButton();
  tafsirRefresh();
  document.title = `${surahOf(current.s).en} ${current.s}:${current.a} — Qur'an Reader`;
}

function openSurah(n, ayah = 1, { play = false } = {}) {
  current = { s: n, a: ayah };
  state.surah = n;
  if (state.view === 'pages') state.page = pageOf(n, ayah);
  save();
  renderReader();
  const target = state.view !== 'pages' && ayah > 1 ? $(`[data-ayah="${ayah}"]`, reader) : null;
  if (target) target.scrollIntoView({ block: 'start' }); else reader.scrollTop = 0;
  afterVerseChange();
  if (play) playVerse(n, ayah); else setNowPlayingLabel();
}

// Make sure a verse is on screen (changing page / surah if needed) and highlight it. Used by playback and tafsir stepping.
function showVerse(s, a, { scroll = false } = {}) {
  current = { s, a };
  const visible = state.view === 'pages'
    ? $(`[data-s="${s}"][data-ayah="${a}"]`, reader)
    : s === state.surah;
  if (!visible) {
    if (state.view === 'pages') { state.page = pageOf(s, a); save(); renderPage(); reader.scrollTop = 0; }
    else { openSurah(s, a); return; }
  }
  afterVerseChange();
  highlightCurrent({ scroll });
}

function stepVerse(dir) {
  const to = adjacentVerse(current.s, current.a, dir);
  if (to) showVerse(to.s, to.a, { scroll: true });
}

function selectVerse(s, a) {
  current = { s, a };
  afterVerseChange();
  highlightCurrent();
  setNowPlayingLabel();
}

function stepContainer(dir) {
  if (state.view === 'pages') goPage(state.page + dir);
  else {
    const n = state.surah + dir;
    if (n >= 1 && n <= 114) openSurah(n);
  }
}

function setView(v) {
  if (state.view === v) return;
  state.view = v;
  if (v === 'pages') state.page = pageOf(current.s, current.a);
  save();
  applyPrefs();
  renderReader();
  if (v !== 'pages') {
    const el = $(`[data-s="${current.s}"][data-ayah="${current.a}"]`, reader);
    if (el && current.a > 1) el.scrollIntoView({ block: 'start' });
  } else {
    reader.scrollTop = 0;
  }
}

// Remember the verse nearest the top of the viewport as the reading position (verse and text views).
let scrollTimer;
reader.addEventListener('scroll', () => {
  if (state.view === 'pages') return;
  clearTimeout(scrollTimer);
  scrollTimer = setTimeout(() => {
    const top = reader.getBoundingClientRect().top;
    const first = $$('[data-ayah]', reader).find((el) => el.getBoundingClientRect().bottom > top + 40);
    if (first) { state.ayah = +first.dataset.ayah; save(); }
  }, 300);
});

// ---------- Bookmarks & copy ----------
function toggleBookmark(s, a) {
  const i = state.bookmarks.findIndex((b) => b.s === s && b.a === a);
  if (i >= 0) { state.bookmarks.splice(i, 1); toast('Removed from saved verses'); }
  else { state.bookmarks.unshift({ s, a }); toast(`Saved ${surahOf(s).en} ${s}:${a}`); }
  save();
  renderSaved();
  updateBookmarkButton();
  const star = $(`.verse[data-s="${s}"][data-ayah="${a}"] [data-act="bookmark"]`, reader);
  if (star) {
    const on = isBookmarked(s, a);
    star.textContent = on ? '★' : '☆';
    star.classList.toggle('on', on);
  }
}

function updateBookmarkButton() {
  const on = isBookmarked(current.s, current.a);
  const btn = $('#bookmark-current');
  btn.textContent = `${on ? '★' : '☆'} Save`;
  btn.classList.toggle('on', on);
}

async function copyVerse(s, a) {
  const v = ayahOf(s, a);
  const text = `${v.a}\n\n${translationText(state.tr1, s, a)}\n— ${surahOf(s).en} ${s}:${a}`;
  try { await navigator.clipboard.writeText(text); toast('Verse copied'); } catch { toast('Could not copy'); }
}

// ---------- Display options ----------
function translationOptionsHtml(withNone) {
  const names = new Intl.DisplayNames(['en'], { type: 'language' });
  const label = (lang) => { try { return names.of(lang) || lang; } catch { return lang; } };
  const groups = new Map();
  for (const t of Q.translations) {
    if (!groups.has(t.lang)) groups.set(t.lang, []);
    groups.get(t.lang).push(t);
  }
  const order = [...groups.keys()].sort((a, b) => (a === 'en' ? -1 : b === 'en' ? 1 : label(a).localeCompare(label(b))));
  return (withNone ? '<option value="">None</option>' : '')
    + order.map((l) => `<optgroup label="${esc(label(l))}">${groups.get(l).map((t) => `<option value="${esc(t.id)}">${esc(t.name)}</option>`).join('')}</optgroup>`).join('');
}

function changeFont(delta) {
  state.arSize = Math.min(72, Math.max(20, state.arSize + delta * 2));
  state.trSize = Math.min(30, Math.max(12, state.trSize + delta));
  save();
  applyPrefs();
  if (state.view === 'pages') fitPage();
}

const displayPop = $('#display-pop');
function closePopover() { displayPop.hidden = true; }

$('#display').addEventListener('click', () => { displayPop.hidden = !displayPop.hidden; });
document.addEventListener('click', (e) => {
  if (!displayPop.hidden && !displayPop.contains(e.target) && e.target !== $('#display')) closePopover();
});

$('#sel-tr1').addEventListener('change', (e) => {
  state.tr1 = e.target.value; save(); rerender();
  if ($('#panel-search').classList.contains('active')) runSearch();
  renderSaved();
});
$('#sel-tr2').addEventListener('change', (e) => { state.tr2 = e.target.value; save(); rerender(); });
$('#chk-showtr').addEventListener('change', (e) => { state.showTr = e.target.checked; save(); rerender(); });
$('#chk-translit').addEventListener('change', (e) => { state.translit = e.target.checked; save(); rerender(); });
$('#chk-wbw').addEventListener('change', (e) => { state.wbw = e.target.checked; save(); rerender(); });
$('#theme-seg').addEventListener('click', (e) => {
  const b = e.target.closest('[data-theme]');
  if (b) { state.theme = b.dataset.theme; save(); applyPrefs(); }
});

// ---------- Events ----------
$$('.tab').forEach((t) => t.addEventListener('click', () => switchTab(t.dataset.tab)));
$('#surah-filter').addEventListener('input', renderSurahList);
$('#search-input').addEventListener('input', runSearch);

// Sidebar lists share one handler: any <li> with data-surah navigates.
$('#sidebar').addEventListener('click', (e) => {
  const li = e.target.closest('li[data-surah]');
  if (li) openSurah(+li.dataset.surah, +(li.dataset.ayah || 1));
});

reader.addEventListener('click', (e) => {
  const act = e.target.closest('[data-act]');
  const verseEl = e.target.closest('[data-ayah]');
  const s = verseEl ? +verseEl.dataset.s : null;
  const a = verseEl ? +verseEl.dataset.ayah : null;
  if (act) {
    switch (act.dataset.act) {
      case 'play': playVerse(s, a); break;
      case 'bookmark': toggleBookmark(s, a); break;
      case 'copy': copyVerse(s, a); break;
      case 'tafsir': selectVerse(s, a); setTafsirOpen(true); break;
      case 'goto': openSurah(+act.dataset.surah); break;
    }
    return;
  }
  if (verseEl) selectVerse(s, a);
});
reader.addEventListener('dblclick', (e) => {
  const el = e.target.closest('[data-ayah]');
  if (el) playVerse(+el.dataset.s, +el.dataset.ayah);
});

$('#prev-surah').addEventListener('click', () => stepContainer(-1));
$('#next-surah').addEventListener('click', () => stepContainer(1));
$('#view-verse').addEventListener('click', () => setView('verse'));
$('#view-flow').addEventListener('click', () => setView('flow'));
$('#view-pages').addEventListener('click', () => setView('pages'));
$('#page-input').addEventListener('change', (e) => goPage(e.target.value));
$('#font-up').addEventListener('click', () => changeFont(1));
$('#font-down').addEventListener('click', () => changeFont(-1));
$('#bookmark-current').addEventListener('click', () => toggleBookmark(current.s, current.a));

let resizeTimer;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => { if (state.view === 'pages') fitPage(); }, 120);
});

document.addEventListener('keydown', (e) => {
  const tag = document.activeElement.tagName;
  const typing = /^(INPUT|SELECT|TEXTAREA)$/.test(tag) && document.activeElement.type !== 'checkbox';
  if (e.key === 'Escape') {
    if (!displayPop.hidden) closePopover(); else if (state.tafsirOpen) setTafsirOpen(false);
    return;
  }
  if (e.ctrlKey && e.key.toLowerCase() === 'f') { e.preventDefault(); switchTab('search'); return; }
  if (e.ctrlKey && (e.key === '=' || e.key === '+')) { e.preventDefault(); changeFont(1); return; }
  if (e.ctrlKey && e.key === '-') { e.preventDefault(); changeFont(-1); return; }
  if (e.altKey && e.key === 'ArrowRight') { stepContainer(1); return; }
  if (e.altKey && e.key === 'ArrowLeft') { stepContainer(-1); return; }
  if (typing || e.ctrlKey || e.altKey || e.metaKey) return;
  const key = e.key.toLowerCase();
  if (e.key === ' ') { e.preventDefault(); togglePlay(); }
  else if (key === 'n') skip(1);
  else if (key === 'p') skip(-1);
  else if (key === 'b') toggleBookmark(current.s, current.a);
  else if (key === 't') setTafsirOpen(!state.tafsirOpen);
});

// ---------- Init ----------
$('#sel-tr1').innerHTML = translationOptionsHtml(false);
$('#sel-tr2').innerHTML = translationOptionsHtml(true);
applyPrefs();
renderJuzList();
renderSurahList();
renderSaved();
runSearch();
if (state.view === 'pages') {
  renderPage();
  afterVerseChange();
} else {
  openSurah(state.surah, state.ayah);
}
setNowPlayingLabel();
if (state.tafsirOpen) renderTafsir();
// Page line-fitting measures text, so redo it once the Arabic font has actually loaded.
document.fonts.load('40px "Amiri Quran"').then(() => { if (state.view === 'pages') fitPage(); });
