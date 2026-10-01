'use strict';
// Madani mushaf view: 604 pages laid out on a 15-row grid exactly like the printed book (8 rows on pages 1-2).
// Page data: data/pages/<p>.json = [[surah, ayah, text, line, flags], ...]  flags: 1 = verse-end marker, 2 = first word of verse.
// With the optional QCF fonts installed, data/qcf/<p>.json holds the matching glyph string for each word.

const MAX_PAGE = 604;
// The paper stretches between these width / height ratios to fill the window (the printed page is about 0.7).
const ASPECT_MIN = 0.62;
const ASPECT_MAX = 0.8;
const STAGE_PAD = 8;
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
    const face = new FontFace(`QCF1_p${p}`, `url(fonts/mushaf/p${p}.woff2)`);
    pageFontLoads.set(p, face.load().then((f) => { document.fonts.add(f); }).catch(() => {}));
  }
  return pageFontLoads.get(p);
}

// How big the pages are: the page fills the window height and as much width as it can (up to ASPECT_MAX);
// two pages show side by side when each can still be reasonably wide.
function layoutMushaf() {
  const aw = stage.clientWidth - 2 * STAGE_PAD;
  const ah = stage.clientHeight - 2 * STAGE_PAD;
  const spread = state.spread && (aw - SPREAD_GAP) / 2 >= ah * ASPECT_MIN * 1.05;
  const room = spread ? (aw - SPREAD_GAP) / 2 : aw;
  const base = Math.min(room, ah * ASPECT_MAX);
  const aspect = Math.min(ASPECT_MAX, Math.max(ASPECT_MIN, base / ah));
  return { spread, width: Math.max(220, base * state.zoom), aspect };
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
  return `<article class="paper${MUSHAF.qcf ? ' qcf' : ''}" data-page="${p}" style="--rows:${p <= 2 ? 8 : 15};--gap:${p <= 2 ? '0.32em' : '0.18em'};--qf:'QCF1_p${p}'">
    <div class="paper-head"><span>الجزء ${toArabicDigits(juz)}</span><span>سورة ${esc(surahOf(first[0]).ar)}</span></div>
    <div class="grid">${body}</div>
    <div class="paper-foot">${toArabicDigits(p)}</div>
  </article>`;
}

// One font size per page: the widest printed line exactly fills the page. Measured once, then scaled with the page.
function fitPaper(el, aspect) {
  const p = +el.dataset.page;
  const key = `${MUSHAF.qcf ? 'q' : 'u'}${MUSHAF.hafs ? 'h' : ''}${Math.round(aspect * 50)}-${p}`; // the row height depends on the aspect
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
    const kFit = (0.995 * 10 * innerW) / Math.max(...natural); // a hair of slack so rounding never pushes a line past the frame
    const k = Math.min(kFit, rowH * 0.8 * 100); // never taller than its row
    fit = { k, ratios: natural.map((n) => (n * (k / 10)) / innerW) };
    fitCache.set(key, fit);
  }
  el.style.setProperty('--k', fit.k);
  lineEls.forEach((l, i) => {
    l.classList.toggle('center', p <= 2 || (l.dataset.ends === '1' && fit.ratios[i] < 0.85));
  });
}

// Size a paper to the layout. Every size on the page derives from its width (--w).
function placePaper(el, L) {
  el.style.width = `${L.width}px`;
  el.style.aspectRatio = String(L.aspect);
  el.style.setProperty('--w', `${L.width}px`);
  fitPaper(el, L.aspect);
}

const FLIP_MS = 620;
const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function paperEl(p) {
  const t = document.createElement('template');
  t.innerHTML = paperHtml(p).trim();
  return t.content.firstElementChild;
}

// Turn a page like a book: in an Arabic book the left page is lifted and turned over the spine onto the right-hand stack
// (forward), or the right page turns back onto the left (backward). The leaf has the outgoing page on its front and the
// incoming page on its back; the pages underneath are the ones being revealed and the ones being covered.
async function playFlip(old, next, dir, L) {
  const [oldRight, oldLeft] = old;
  const [newRight, newLeft] = next;
  const W = L.width;
  const H = W / L.aspect;
  const book = document.createElement('div');
  book.className = 'book';
  book.style.width = `${2 * W + SPREAD_GAP}px`;
  book.style.height = `${H}px`;

  const slot = (p, side) => {
    const d = document.createElement('div');
    d.className = `slot ${side}`;
    d.style.width = `${W}px`;
    d.append(paperEl(p));
    return d;
  };
  const under = dir > 0 ? [slot(newLeft, 'left'), slot(oldRight, 'right')] : [slot(oldLeft, 'left'), slot(newRight, 'right')];

  const leaf = document.createElement('div');
  leaf.className = `leaf ${dir > 0 ? 'fwd' : 'back'}`;
  leaf.style.width = `${W}px`;
  leaf.style.height = `${H}px`;
  leaf.style[dir > 0 ? 'left' : 'right'] = '0';
  leaf.style.transformOrigin = dir > 0 ? `calc(100% + ${SPREAD_GAP / 2}px) 50%` : `${-SPREAD_GAP / 2}px 50%`; // the spine
  const front = document.createElement('div');
  front.className = 'face front';
  front.append(paperEl(dir > 0 ? oldLeft : oldRight));
  const back = document.createElement('div');
  back.className = 'face back';
  back.append(paperEl(dir > 0 ? newRight : newLeft));
  leaf.append(front, back);

  book.append(...under, leaf);
  reader.innerHTML = '';
  reader.append(book);
  $$('.paper', book).forEach((el) => placePaper(el, L));
  highlightCurrent();
  void book.offsetWidth; // commit the starting state before turning
  leaf.classList.add('turning');
  await new Promise((resolve) => {
    leaf.addEventListener('transitionend', resolve, { once: true });
    setTimeout(resolve, FLIP_MS + 150);
  });
}

async function renderMushaf() {
  const token = ++renderToken;
  const L = layoutMushaf();
  const pages = viewPages(state.page, L.spread);
  await Promise.all([fontsReady, ...pages.map(pageFont)]);
  if (token !== renderToken || state.view !== 'mushaf') return;

  const old = shownPages;
  const hadPages = reader.classList.contains('mushaf') && old.length > 0;
  const changed = hadPages && !(old.length === pages.length && old.every((p, i) => p === pages[i]));
  shownPages = pages;
  reader.className = 'mushaf';

  let turned = false;
  if (changed && state.flipAnim && !reducedMotion() && L.spread && old.length === 2 && pages.length === 2 && Math.abs(pages[0] - old[0]) === 2) {
    await playFlip(old, pages, pages[0] > old[0] ? 1 : -1, L);
    if (token !== renderToken) return; // another page turn started meanwhile
    turned = true;
  }

  reader.innerHTML = `<div class="spread${changed && !turned ? ' fade-in' : ''}">${pages.map(paperHtml).join('')}</div>`;
  $$('.paper', reader).forEach((el) => placePaper(el, L));
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
