'use strict';
// Madani mushaf view: 604 pages laid out on a 15-row grid exactly like the printed book (8 rows on pages 1-2).
// Page data: data/pages/<p>.json = [[surah, ayah, text, line, flags], ...]  flags: 1 = verse-end marker, 2 = first word of verse.
// With the optional QCF fonts installed, data/qcf/<p>.json holds the matching glyph string for each word.

const MAX_PAGE = 604;
const PAGE_ASPECT = 0.7; // paper width / height
const STAGE_PAD = 14;
const SPREAD_GAP = 12;
const ZOOM_MIN = 0.5;
const ZOOM_MAX = 3;

const fitCache = new Map(); // page key -> { k, ratios }: font size and line fill, as fractions of the page width
const pageFontLoads = new Map();
let renderToken = 0;
let shownPages = [];

const pageWords = (p) => data(`pages/${p}.json`);
// A printed spread has the odd page on the right and the next page on the left: (1,2) (3,4) ...
const spreadOf = (p) => { const right = p % 2 ? p : p - 1; return [right, right + 1].filter((n) => n <= MAX_PAGE); };

function pageFont(p) {
  if (!MUSHAF.qcf) return Promise.resolve();
  if (!pageFontLoads.has(p)) {
    const face = new FontFace(`QCF2_p${p}`, `url(fonts/mushaf/p${p}.woff2)`);
    pageFontLoads.set(p, face.load().then((f) => { document.fonts.add(f); }).catch(() => {}));
  }
  return pageFontLoads.get(p);
}

// How big the pages are: the page fits the window height; two pages show side by side if they fit.
function layoutMushaf() {
  const aw = stage.clientWidth - 2 * STAGE_PAD;
  const ah = stage.clientHeight - 2 * STAGE_PAD;
  const fitW = ah * PAGE_ASPECT;
  const spread = state.spread && 2 * fitW + SPREAD_GAP <= aw;
  const base = spread ? fitW : Math.min(fitW, aw);
  return { spread, width: Math.max(220, base * state.zoom) };
}
const viewPages = (p, spread) => (spread ? spreadOf(p) : [p]);

function wordHtml(w, glyph) {
  const attrs = `data-s="${w[0]}" data-ayah="${w[1]}"`;
  const end = w[4] & 1;
  if (glyph != null) return `<span class="w${end ? ' end' : ''}" ${attrs}>${esc(glyph)}</span>`;
  return `<span class="w${end ? ' end mark' : ''}" ${attrs}>${esc(w[2])}</span>`;
}

function paperHtml(p) {
  const words = pageWords(p);
  const glyphs = MUSHAF.qcf ? data(`qcf/${p}.json`) : null;
  const lines = new Map();
  words.forEach((w, i) => {
    if (!lines.has(w[3])) lines.set(w[3], []);
    lines.get(w[3]).push(i);
  });

  let body = '';
  for (const [lineNo, idxs] of [...lines.entries()].sort((a, b) => a[0] - b[0])) {
    // A surah begins on this line: its banner (and Bismillah) sit in the rows reserved above it, as in the print.
    for (const i of idxs) {
      const w = words[i];
      if ((w[4] & 2) && w[1] === 1) {
        const hasBismillah = w[0] !== 1 && w[0] !== 9;
        body += `<div class="banner" style="grid-row:${Math.max(1, lineNo - (hasBismillah ? 2 : 1))}"><span>سورة ${esc(surahOf(w[0]).ar)}</span></div>`;
        if (hasBismillah) body += `<div class="bism" style="grid-row:${lineNo - 1}">${esc(Q.bismillah)}</div>`;
      }
    }
    const last = words[idxs[idxs.length - 1]];
    const endsSurah = (last[4] & 1) && last[1] === surahOf(last[0]).ayahs.length;
    body += `<div class="line" data-ends="${endsSurah ? 1 : 0}" style="grid-row:${lineNo}">`
      + idxs.map((i) => wordHtml(words[i], glyphs ? glyphs[i] : null)).join('') + '</div>';
  }

  const first = words[0];
  const juz = ayahOf(first[0], first[1]).juz;
  return `<article class="paper${MUSHAF.qcf ? ' qcf' : ''}" data-page="${p}" style="--rows:${p <= 2 ? 8 : 15};--qf:'QCF2_p${p}'">
    <div class="paper-head"><span>الجزء ${toArabicDigits(juz)}</span><span>سورة ${esc(surahOf(first[0]).ar)}</span></div>
    <div class="grid">${body}</div>
    <div class="paper-foot">${toArabicDigits(p)}</div>
  </article>`;
}

// One font size per page: the widest printed line exactly fills the page. Measured once, then scaled with the page.
function fitPaper(el) {
  const p = +el.dataset.page;
  const key = `${MUSHAF.qcf ? 'q' : 'u'}${MUSHAF.hafs ? 'h' : ''}${p}`;
  const lineEls = $$('.line', el);
  let fit = fitCache.get(key);
  if (!fit) {
    const grid = $('.grid', el);
    const W = parseFloat(el.style.width);
    el.classList.add('measuring'); // font size 10% of the page width, lines at their natural width
    const natural = lineEls.map((l) => l.getBoundingClientRect().width / W);
    el.classList.remove('measuring');
    const innerW = grid.clientWidth / W;
    const rowH = grid.clientHeight / (p <= 2 ? 8 : 15) / W;
    const kFit = (10 * innerW) / Math.max(...natural);
    const k = Math.min(kFit, rowH * 0.74 * 100); // never taller than its row
    fit = { k, ratios: natural.map((n) => (n * (k / 10)) / innerW) };
    fitCache.set(key, fit);
  }
  el.style.setProperty('--k', fit.k);
  lineEls.forEach((l, i) => {
    l.classList.toggle('center', p <= 2 || (l.dataset.ends === '1' && fit.ratios[i] < 0.85));
  });
}

async function renderMushaf() {
  const token = ++renderToken;
  const L = layoutMushaf();
  const pages = viewPages(state.page, L.spread);
  await Promise.all([fontsReady, ...pages.map(pageFont)]);
  if (token !== renderToken || state.view !== 'mushaf') return;

  shownPages = pages;
  reader.className = 'mushaf';
  reader.innerHTML = `<div class="spread">${pages.map(paperHtml).join('')}</div>`;
  $$('.paper', reader).forEach((el) => {
    el.style.width = `${L.width}px`;
    el.style.setProperty('--w', `${L.width}px`); // every size on the page derives from this
    fitPaper(el);
  });
  highlightCurrent();
  updateMushafChrome();
  for (const n of [pages[0] - 2, pages[0] - 1, pages[pages.length - 1] + 1, pages[pages.length - 1] + 2]) {
    if (n >= 1 && n <= MAX_PAGE) pageFont(n); // warm the next flips
  }
}

function updateMushafChrome() {
  const mushaf = state.view === 'mushaf';
  $('#flip-prev').hidden = !mushaf;
  $('#flip-next').hidden = !mushaf;
  $('#flip-prev').disabled = shownPages[0] <= 1;
  $('#flip-next').disabled = shownPages[shownPages.length - 1] >= MAX_PAGE;
  $('#progress i').style.width = `${((current.s ? pageOf(current.s, current.a) : state.page) / MAX_PAGE) * 100}%`;
}

function mushafStep(dir) {
  const pages = viewPages(state.page, layoutMushaf().spread);
  goPage(dir > 0 ? pages[pages.length - 1] + 1 : pages[0] - 1);
}

function goPage(p, { select = true } = {}) {
  p = Math.min(MAX_PAGE, Math.max(1, Math.round(+p) || 1));
  state.page = p;
  if (select) {
    const v = firstVerseOfPage(viewPages(p, layoutMushaf().spread)[0]);
    current = { s: v.s, a: v.a };
    afterVerseChange();
    setNowPlayingLabel();
  }
  save();
  renderMushaf().then(() => { reader.scrollTop = 0; });
}

function setZoom(z) {
  state.zoom = Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, Math.round(z * 100) / 100));
  save();
  renderMushaf();
  updateZoomLabel();
}

// Highlight every word of the current verse that is on screen (mushaf and verses views alike).
function highlightCurrent({ scroll = false } = {}) {
  $$('.current', reader).forEach((el) => el.classList.remove('current'));
  const els = $$(`[data-s="${current.s}"][data-ayah="${current.a}"]`, reader);
  els.forEach((el) => el.classList.add('current'));
  if (scroll && els.length) els[0].scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' });
}
