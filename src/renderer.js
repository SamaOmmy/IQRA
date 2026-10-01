'use strict';
// Main UI glue: verses view, navigation, settings, zoom, keyboard. Loaded last.

// ---------- Verses view ----------
function arabicHtml(sn, v) {
  const text = arabicText(sn, v.n);
  if (!state.wbw) return esc(text);
  const words = wordsOf(sn, v.n);
  if (!words.length) return esc(text);
  return '<div class="wbw" dir="rtl">' + words.map(([uth, meaning, translit, qpc]) =>
    `<span class="wd"><span class="wd-ar">${esc(MUSHAF.hafs ? (qpc || uth) : uth)}</span>${translit ? `<span class="wd-tl">${esc(translit)}</span>` : ''}<span class="wd-tr">${esc(meaning)}</span></span>`).join('') + '</div>';
}

function translationsHtml(sn, a) {
  let out = '';
  if (state.translit) out += `<div class="translit">${esc(transliterationText(sn, a))}</div>`;
  if (!state.showTr) return out;
  const ids = [state.tr1, state.tr2].filter(Boolean);
  for (const id of ids) {
    out += `<div class="tr" dir="${isRtlTranslation(id) ? 'rtl' : 'ltr'}">`
      + (ids.length > 1 ? `<span class="tr-name">${esc(translationMeta(id).name)}</span>` : '')
      + `${esc(translationText(id, sn, a))}</div>`;
  }
  return out;
}

function renderVerses() {
  const s = surahOf(state.surah);
  const showBismillah = s.n !== 1 && s.n !== 9;
  const head = `
    <header class="v-head">
      <div class="v-title">سورة ${esc(s.ar)}</div>
      <div class="v-meta">${s.n}. ${esc(s.en)} · ${esc(s.meaning)} · ${s.type === 'Meccan' ? 'Meccan' : 'Medinan'} · ${s.ayahs.length} verses</div>
    </header>
    ${showBismillah ? `<div class="v-bism">${esc(Q.bismillah)}</div>` : ''}`;

  const body = s.ayahs.map((a) => `
    <article class="v" data-s="${s.n}" data-ayah="${a.n}">
      <div class="v-side">
        <span class="v-num">${a.n}</span>
        <span class="v-actions">
          <button class="vbtn" data-act="play" title="Listen">▶</button>
          <button class="vbtn${isBookmarked(s.n, a.n) ? ' on' : ''}" data-act="bookmark" title="Save verse">${isBookmarked(s.n, a.n) ? '★' : '☆'}</button>
          <button class="vbtn" data-act="copy" title="Copy verse">⧉</button>
          <button class="vbtn" data-act="study" title="Study: translation, words, tafsir">ⓘ</button>
        </span>
      </div>
      <div class="v-main">
        <div class="v-ar">${arabicHtml(s.n, a)}${a.sajda ? ' <span class="sajda" title="Prostration verse">۩</span>' : ''}</div>
        ${translationsHtml(s.n, a.n)}
      </div>
    </article>`).join('');

  const nav = `<div class="end-nav">
    ${s.n > 1 ? `<button class="btn" data-act="goto" data-surah="${s.n - 1}">‹ ${esc(surahOf(s.n - 1).en)}</button>` : '<span></span>'}
    ${s.n < 114 ? `<button class="btn" data-act="goto" data-surah="${s.n + 1}">${esc(surahOf(s.n + 1).en)} ›</button>` : '<span></span>'}
  </div>`;

  reader.className = 'verses';
  reader.innerHTML = `<div class="verses-wrap">${head}${body}${nav}</div>`;
  highlightCurrent();
}

// Re-render in place without losing the scroll position.
function rerenderView() {
  if (state.view === 'mushaf') { renderMushaf(); return; }
  if (state.view === 'discover') { const t = reader.scrollTop; renderDiscover(); reader.scrollTop = t; return; }
  const top = reader.scrollTop;
  renderVerses();
  reader.scrollTop = top;
}

// ---------- Navigation ----------
function updateLocation() {
  if (state.view === 'discover') {
    const h = hijriOf(new Date());
    $('#loc-main').textContent = 'Discover';
    $('#loc-sub').textContent = `${h.d} ${HIJRI_MONTHS[h.m - 1]} ${h.y} AH`;
    document.title = 'Discover \u00b7 IQRA';
    return;
  }
  const s = surahOf(current.s);
  $('#loc-main').textContent = `${s.n}. ${s.en}`;
  $('#loc-sub').textContent = `${s.ar} · Juz ${ayahOf(current.s, current.a).juz} · Page ${pageOf(current.s, current.a)} · Verse ${current.a}`;
  document.title = `${s.en} ${current.s}:${current.a} · IQRA`;
  if (state.view === 'mushaf') updateMushafChrome();
}

function afterVerseChange() {
  state.surah = current.s;
  state.ayah = current.a;
  markActiveSurah();
  updateBookmarkButton();
  updateLocation();
  studyRefresh();
}

function renderCurrentView() {
  if (state.view === 'discover') {
    renderDiscover();
    reader.scrollTop = 0;
  } else if (state.view === 'mushaf') {
    renderMushaf().then(() => { reader.scrollTop = 0; });
  } else {
    renderVerses();
    const target = current.a > 1 ? $(`[data-ayah="${current.a}"]`, reader) : null;
    if (target) target.scrollIntoView({ block: 'start' }); else reader.scrollTop = 0;
  }
}

function navigateTo(s, a = 1, { play = false, page = 0 } = {}) {
  current = { s, a };
  state.surah = s;
  state.ayah = a;
  if (state.view === 'mushaf') state.page = page || pageOf(s, a);
  save();
  afterVerseChange();
  renderCurrentView();
  if (play) playVerse(s, a); else setNowPlayingLabel();
}
const openSurah = navigateTo;

// Make sure a verse is on screen (changing page or surah if needed) and highlight it. Used by playback and stepping.
function showVerse(s, a, { scroll = false } = {}) {
  current = { s, a };
  if (state.view === 'discover') { setNowPlayingLabel(); return; } // listening from Discover must not pull you into the reader
  const present = state.view === 'mushaf'
    ? $(`[data-s="${s}"][data-ayah="${a}"]`, reader)
    : s === state.surah;
  if (!present) {
    if (state.view === 'mushaf') { state.page = pageOf(s, a); save(); afterVerseChange(); renderMushaf(); return; }
    navigateTo(s, a);
    return;
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
  if (state.view === 'mushaf') mushafStep(dir);
  else if (state.surah + dir >= 1 && state.surah + dir <= 114) navigateTo(state.surah + dir);
}

function setView(v) {
  if (state.view === v) return;
  state.view = v;
  if (v !== 'discover') state.readView = v;
  if (v === 'mushaf') state.page = pageOf(current.s, current.a);
  save();
  applyPrefs();
  renderCurrentView();
}

// Remember the verse nearest the top of the viewport as the reading position (verses view).
let scrollTimer;
reader.addEventListener('scroll', () => {
  if (state.view !== 'verses') return;
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
  if (drawerPanel === 'saved') renderSaved();
  updateBookmarkButton();
  const star = $(`.v[data-s="${s}"][data-ayah="${a}"] [data-act="bookmark"]`, reader);
  if (star) {
    const on = isBookmarked(s, a);
    star.textContent = on ? '★' : '☆';
    star.classList.toggle('on', on);
  }
}

function updateBookmarkButton() {
  const on = isBookmarked(current.s, current.a);
  const btn = $('#study-save');
  btn.textContent = on ? '★' : '☆';
  btn.classList.toggle('on', on);
  btn.title = on ? 'Remove from saved verses (B)' : 'Save this verse (B)';
}

async function copyVerse(s, a) {
  const text = `${arabicText(s, a)}\n\n${translationText(state.tr1, s, a)}\n— ${surahOf(s).en} ${s}:${a}`;
  try { await navigator.clipboard.writeText(text); toast('Verse copied'); } catch { toast('Could not copy'); }
}

// ---------- Zoom ----------
function updateZoomLabel() {
  const pct = state.view === 'mushaf' ? state.zoom * 100 : (state.arSize / defaults.arSize) * 100;
  $('#zoom-label').textContent = `${Math.round(pct)}%`;
}

function setVersesSize(arSize) {
  state.arSize = Math.min(64, Math.max(20, Math.round(arSize)));
  state.trSize = Math.round((defaults.trSize * state.arSize / defaults.arSize) * 2) / 2;
  save();
  applyPrefs();
}

function zoomBy(dir) {
  if (state.view === 'mushaf') setZoom(state.zoom * (dir > 0 ? 1.12 : 1 / 1.12));
  else setVersesSize(state.arSize + dir * 2);
}
function zoomReset() {
  if (state.view === 'mushaf') setZoom(1); else setVersesSize(defaults.arSize);
}

// ---------- Preferences ----------
function applyPrefs() {
  const root = document.documentElement;
  root.dataset.theme = state.theme;
  root.style.setProperty('--ar-size', `${state.arSize}px`);
  root.style.setProperty('--tr-size', `${state.trSize}px`);
  $('#view-mushaf').classList.toggle('active', state.view === 'mushaf');
  $('#view-verses').classList.toggle('active', state.view === 'verses');
  $('#view-discover').classList.toggle('active', state.view === 'discover');
  $('.zoom').hidden = state.view === 'discover';
  $('#flip-prev').hidden = state.view !== 'mushaf';
  $('#flip-next').hidden = state.view !== 'mushaf';
  stage.classList.toggle('is-mushaf', state.view === 'mushaf');
  $('#chk-spread').checked = state.spread;
  $('#chk-flip').checked = state.flipAnim;
  $('#chk-showtr').checked = state.showTr;
  $('#chk-translit').checked = state.translit;
  $('#chk-wbw').checked = state.wbw;
  $('#sel-tr1').value = state.tr1;
  $('#sel-tr2').value = state.tr2;
  $('#p-continuous').checked = state.continuous;
  $('#speed').value = String(state.speed);
  $('#reciter').value = state.reciter;
  $$('#theme-seg .seg-btn').forEach((b) => b.classList.toggle('active', b.dataset.theme === state.theme));
  $('#btn-study').classList.toggle('on', state.studyOpen);
  studyPanel.hidden = !state.studyOpen;
  $('#font-note').textContent = MUSHAF.qcf
    ? 'Script: the printed Madani mushaf (King Fahd Glorious Qur\'an Printing Complex).'
    : 'Script: Old Madina, an open font after the classic Madina Mushaf. (Run "npm run fetch-fonts" when building from source to use the printed glyphs.)';
  updateZoomLabel();
}

// Called when the translation choice changes anywhere (settings, study panel).
function onTranslationChanged() {
  $('#sel-tr1').value = state.tr1;
  $('#sel-tr2').value = state.tr2;
  if (state.view === 'verses' || state.view === 'discover') rerenderView();
  if (drawerPanel === 'saved') renderSaved();
  if (drawerPanel === 'search') runSearch();
}

const modal = $('#modal');
function openSettings() { modal.hidden = false; }
function closeSettings() { modal.hidden = true; }

$('#btn-settings').addEventListener('click', openSettings);
$('#settings-close').addEventListener('click', closeSettings);
modal.addEventListener('mousedown', (e) => { if (e.target === modal) closeSettings(); });
$('#sel-tr1').addEventListener('change', (e) => { state.tr1 = e.target.value; save(); onTranslationChanged(); studyRefresh(); });
$('#sel-tr2').addEventListener('change', (e) => { state.tr2 = e.target.value; save(); onTranslationChanged(); studyRefresh(); });
$('#chk-flip').addEventListener('change', (e) => { state.flipAnim = e.target.checked; save(); });
$('#chk-spread').addEventListener('change', (e) => { state.spread = e.target.checked; save(); if (state.view === 'mushaf') renderMushaf(); });
$('#chk-showtr').addEventListener('change', (e) => { state.showTr = e.target.checked; save(); if (state.view === 'verses') rerenderView(); });
$('#chk-translit').addEventListener('change', (e) => { state.translit = e.target.checked; save(); if (state.view === 'verses') rerenderView(); });
$('#chk-wbw').addEventListener('change', (e) => { state.wbw = e.target.checked; save(); if (state.view === 'verses') rerenderView(); });
$('#theme-seg').addEventListener('click', (e) => {
  const b = e.target.closest('[data-theme]');
  if (b) { state.theme = b.dataset.theme; save(); applyPrefs(); }
});

// ---------- Events ----------
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
      case 'study': selectVerse(s, a); setStudyOpen(true); break;
      case 'goto': navigateTo(+act.dataset.surah); break;
    }
    return;
  }
  if (verseEl) selectVerse(s, a);
});
reader.addEventListener('dblclick', (e) => {
  const el = e.target.closest('[data-ayah]');
  if (el) playVerse(+el.dataset.s, +el.dataset.ayah);
});

$('#view-mushaf').addEventListener('click', () => setView('mushaf'));
$('#view-verses').addEventListener('click', () => setView('verses'));
$('#view-discover').addEventListener('click', () => setView('discover'));
$('#flip-next').addEventListener('click', () => mushafStep(1));
$('#flip-prev').addEventListener('click', () => mushafStep(-1));
$('#zoom-in').addEventListener('click', () => zoomBy(1));
$('#zoom-out').addEventListener('click', () => zoomBy(-1));
$('#zoom-label').addEventListener('click', zoomReset);
$('#study-save').addEventListener('click', () => toggleBookmark(current.s, current.a));

stage.addEventListener('wheel', (e) => {
  if (!e.ctrlKey) return;
  e.preventDefault();
  zoomBy(e.deltaY < 0 ? 1 : -1);
}, { passive: false });

// Re-lay-out the pages when the window (or the study panel) changes the space available.
let layoutFrame = 0;
new ResizeObserver(() => {
  if (state.view !== 'mushaf') return;
  cancelAnimationFrame(layoutFrame);
  layoutFrame = requestAnimationFrame(renderMushaf);
}).observe(stage);

function closeTopmost() {
  if (!paletteWrap.hidden) closePalette();
  else if (!modal.hidden) closeSettings();
  else if (!drawerEl.hidden) closeDrawer();
  else if (state.studyOpen) setStudyOpen(false);
  else if (state.view === 'discover') discoverBack();
}

document.addEventListener('keydown', (e) => {
  const tag = document.activeElement.tagName;
  const typing = /^(INPUT|SELECT|TEXTAREA)$/.test(tag) && document.activeElement.type !== 'checkbox';
  const key = e.key.toLowerCase();
  if (e.key === 'Escape') { closeTopmost(); return; }
  if (e.ctrlKey && key === 'k') { e.preventDefault(); openPalette(); return; }
  if (e.ctrlKey && key === 'f') { e.preventDefault(); openDrawer('search'); return; }
  if (e.ctrlKey && key === 'l') { e.preventDefault(); toggleDrawer('library'); return; }
  if (e.ctrlKey && (e.key === '=' || e.key === '+')) { e.preventDefault(); zoomBy(1); return; }
  if (e.ctrlKey && e.key === '-') { e.preventDefault(); zoomBy(-1); return; }
  if (e.ctrlKey && e.key === '0') { e.preventDefault(); zoomReset(); return; }
  if (e.altKey && e.key === 'ArrowRight') { stepContainer(1); return; }
  if (e.altKey && e.key === 'ArrowLeft') { stepContainer(-1); return; }
  if (typing || e.ctrlKey || e.altKey || e.metaKey || !paletteWrap.hidden || !modal.hidden) return;
  if (state.view === 'mushaf' && e.key === 'ArrowLeft') { mushafStep(1); e.preventDefault(); } // the book turns right to left
  else if (state.view === 'mushaf' && e.key === 'ArrowRight') { mushafStep(-1); e.preventDefault(); }
  else if (state.view === 'mushaf' && e.key === 'PageDown') { mushafStep(1); e.preventDefault(); }
  else if (state.view === 'mushaf' && e.key === 'PageUp') { mushafStep(-1); e.preventDefault(); }
  else if (e.key === ' ') { e.preventDefault(); togglePlay(); }
  else if (key === 'n') skip(1);
  else if (key === 'p') skip(-1);
  else if (key === 'b') toggleBookmark(current.s, current.a);
  else if (key === 't') setStudyOpen(!state.studyOpen);
});

// ---------- Init ----------
$('#sel-tr1').innerHTML = translationOptionsHtml(false, state.tr1);
$('#sel-tr2').innerHTML = translationOptionsHtml(true, state.tr2);
applyPrefs();
renderSurahList();
renderJuzList();
renderSaved();
runSearch();
afterVerseChange();
if (state.view === 'mushaf') renderMushaf(); else renderCurrentView();
setNowPlayingLabel();
if (state.studyOpen) renderStudy();
