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

const FLIP_MS = 1050;
const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function paperEl(p) {
  const t = document.createElement('template');
  t.innerHTML = paperHtml(p).trim();
  return t.content.firstElementChild;
}

// Turn a page like real paper. The leaf (the left page going forward in an Arabic book, the right page going back) is cut into
// thin strips that each rotate about the spine. Their angles follow a travelling wave: the free edge lifts first, the paper
// bends over its own weight, and the part by the spine turns last, so the sheet curls instead of swinging like a door.
// The pages underneath (real DOM) are the one being revealed and the one being covered.
//
// Both sides of the leaf are painted once onto canvases from the laid-out page (every word is drawn where the browser put it).
// Each frame then draws the strips onto one overlay canvas with perspective, shading and a soft cast shadow.
const CURL_STRIPS = 56;
const CURL_LAG = 0.74;        // how far the free edge leads the spine (0 = rigid door, 1 = very floppy)
const CURL_PERSPECTIVE = 2600; // camera distance in CSS px
const clamp01 = (x) => Math.min(1, Math.max(0, x));
const easeSine = (x) => -(Math.cos(Math.PI * x) - 1) / 2;
const nextFrame = () => new Promise((r) => requestAnimationFrame(() => r()));

function roundRectPath(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

// Paint a laid-out .paper element onto a canvas, reading every position from the DOM.
function snapshotPaper(el) {
  const dpr = window.devicePixelRatio || 1;
  const box = el.getBoundingClientRect();
  const W = box.width;
  const H = box.height;
  const cv = document.createElement('canvas');
  cv.width = Math.round(W * dpr);
  cv.height = Math.round(H * dpr);
  const ctx = cv.getContext('2d');
  ctx.scale(cv.width / W, cv.height / H);
  const root = getComputedStyle(document.documentElement);
  const color = (name) => root.getPropertyValue(name).trim();
  const cs = getComputedStyle(el);
  const u = W / 100;

  ctx.fillStyle = cs.backgroundColor;
  ctx.fillRect(0, 0, W, H);
  ctx.lineWidth = 1;
  ctx.strokeStyle = cs.borderTopColor;
  ctx.strokeRect(0.5, 0.5, W - 1, H - 1);
  ctx.strokeStyle = color('--gold');
  ctx.globalAlpha = 0.5;
  ctx.strokeRect(0.7 * u + 0.5, 0.7 * u + 0.5, W - 1.4 * u - 1, H - 1.4 * u - 1);
  ctx.globalAlpha = 1;

  const rel = (node) => {
    const r = node.getBoundingClientRect();
    return { x: r.left - box.left, y: r.top - box.top, w: r.width, h: r.height };
  };

  for (const banner of $$('.banner', el)) {
    const r = rel(banner);
    roundRectPath(ctx, r.x, r.y, r.w, r.h, 0.9 * u);
    ctx.globalAlpha = 0.09;
    ctx.fillStyle = color('--gold');
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.lineWidth = 1;
    ctx.strokeStyle = color('--gold');
    roundRectPath(ctx, r.x + 0.5, r.y + 0.5, r.w - 1, r.h - 1, 0.9 * u);
    ctx.stroke();
    ctx.lineWidth = 0.45 * u;
    ctx.strokeStyle = cs.backgroundColor;
    roundRectPath(ctx, r.x + 1 + 0.225 * u, r.y + 1 + 0.225 * u, r.w - 2 - 0.45 * u, r.h - 2 - 0.45 * u, 0.7 * u);
    ctx.stroke();
    ctx.lineWidth = 1;
    ctx.globalAlpha = 0.55;
    ctx.strokeStyle = color('--gold');
    roundRectPath(ctx, r.x + 1 + 0.45 * u, r.y + 1 + 0.45 * u, r.w - 2 - 0.9 * u, r.h - 2 - 0.9 * u, 0.5 * u);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  ctx.direction = 'rtl';
  ctx.textAlign = 'center';
  // Words share a font, so read it once; baseline metrics are cached per font string.
  const metrics = new Map();
  const baselineOf = (font, text) => {
    let m = metrics.get(font);
    if (!m) { const t = ctx.measureText(text); m = { a: t.fontBoundingBoxAscent, d: t.fontBoundingBoxDescent }; metrics.set(font, m); }
    return m;
  };
  const draw = (node, font, fill) => {
    const text = node.textContent;
    if (!text.trim()) return;
    const r = rel(node);
    ctx.font = font;
    const { a, d } = baselineOf(font, text);
    ctx.fillStyle = fill;
    ctx.fillText(text, r.x + r.w / 2, r.y + (r.h - (a + d)) / 2 + a);
  };

  const firstWord = $('.w:not(.mark)', el);
  const wordStyle = firstWord ? getComputedStyle(firstWord) : cs;
  const markNode = $('.w.mark', el);
  const markStyle = markNode ? getComputedStyle(markNode) : null;
  for (const node of $$('.w', el)) {
    const r = rel(node);
    if (node.classList.contains('current')) {
      roundRectPath(ctx, r.x, r.y, r.w, r.h, 0.14 * parseFloat(wordStyle.fontSize));
      ctx.fillStyle = color('--hl');
      ctx.fill();
    }
    if (node.classList.contains('mark')) { // the verse-number circle of the open-font pages
      ctx.lineWidth = 1;
      ctx.strokeStyle = markStyle.borderTopColor;
      roundRectPath(ctx, r.x + 0.5, r.y + 0.5, r.w - 1, r.h - 1, Math.min(r.w, r.h) / 2);
      ctx.stroke();
      draw(node, markStyle.font, markStyle.color);
    } else {
      draw(node, wordStyle.font, wordStyle.color);
    }
  }
  for (const node of $$('.paper-head span, .paper-foot, .bism, .banner span', el)) {
    const s = getComputedStyle(node);
    draw(node, s.font, s.color);
  }
  return cv;
}

// Returns the overlay canvas (already positioned inside `book`), after the animation has finished.
async function playFlip(old, next, dir, L) {
  const [oldRight, oldLeft] = old;
  const [newRight, newLeft] = next;
  const W = L.width;
  const H = W / L.aspect;
  const G = SPREAD_GAP;
  const fwd = dir > 0; // forward: the left page lifts and lands on the right
  const dpr = window.devicePixelRatio || 1;
  const N = CURL_STRIPS;
  const sw = W / N;
  const sign = fwd ? 1 : -1;
  const bookW = 2 * W + G;
  const margin = Math.round(W * 0.16); // the lifted paper comes towards you and is drawn larger than the page

  const book = document.createElement('div');
  book.className = 'book';
  book.style.width = `${bookW}px`;
  book.style.height = `${H}px`;

  const slot = (p, side) => {
    const d = document.createElement('div');
    d.className = `slot ${side}`;
    d.style.width = `${W}px`;
    d.append(paperEl(p));
    return d;
  };
  const under = fwd ? [slot(newLeft, 'left'), slot(oldRight, 'right')] : [slot(oldLeft, 'left'), slot(newRight, 'right')];

  // The two sides of the leaf are laid out in a hidden stash so they can be painted onto canvases.
  const frontPaper = paperEl(fwd ? oldLeft : oldRight);
  const backPaper = paperEl(fwd ? newRight : newLeft);
  const stash = document.createElement('div');
  stash.className = 'stash';
  stash.append(frontPaper, backPaper);
  book.append(...under, stash);
  reader.innerHTML = '';
  reader.append(book);
  $$('.paper', book).forEach((el) => placePaper(el, L));
  highlightCurrent();
  const frontCanvas = snapshotPaper(frontPaper);
  const backCanvas = snapshotPaper(backPaper);
  stash.remove();

  const cv = document.createElement('canvas');
  cv.className = 'curl';
  cv.width = Math.round((bookW + 2 * margin) * dpr);
  cv.height = Math.round((H + 2 * margin) * dpr);
  cv.style.cssText = `left:${-margin}px;top:${-margin}px;width:${bookW + 2 * margin}px;height:${H + 2 * margin}px`;
  const ctx = cv.getContext('2d');
  const cx = bookW / 2;
  const oy = H * 0.35;
  const d = CURL_PERSPECTIVE;
  const spineX = W + G / 2;
  const sx = (src) => src.width / W; // source pixels per CSS px

  const angle = (u, p) => Math.PI * easeSine(clamp01(p * (1 + CURL_LAG) - (1 - u) * CURL_LAG)); // u: 0 at the spine, 1 at the free edge

  const draw = (p) => {
    ctx.setTransform(dpr, 0, 0, dpr, margin * dpr, margin * dpr);
    ctx.clearRect(-margin, -margin, bookW + 2 * margin, H + 2 * margin);

    // The chain of strips from the spine out: each continues from where the previous one ends.
    const dirOf = (th) => ({ x: -sign * Math.cos(th), z: Math.sin(th) });
    const th0 = angle(0, p);
    let px = spineX + (G / 2) * dirOf(th0).x;
    let pz = (G / 2) * dirOf(th0).z;
    const quads = [];
    for (let i = 0; i < N; i++) {
      const th = angle((i + 0.5) / N, p);
      const dv = dirOf(th);
      const ex = px + sw * dv.x;
      const ez = pz + sw * dv.z;
      quads.push({ i, th, ax: px, az: pz, bx: ex, bz: ez });
      px = ex;
      pz = ez;
    }
    // Shade by the angle at each edge (not per strip) so the sheet darkens smoothly where it curves.
    const edgeAngle = (i) => angle(clamp01(i / N), p);
    const darkAt = (th, u) => 0.5 * Math.sin(th) * (0.55 + 0.45 * u); // the curved part catches less light
    quads.forEach((q) => { q.dA = darkAt(edgeAngle(q.i), q.i / N); q.dB = darkAt(edgeAngle(q.i + 1), (q.i + 1) / N); });
    const proj = (x, z) => { const s = d / (d - z); return { x: cx + (x - cx) * s, s }; };

    // Soft shadow of the lifted paper on the page below.
    if (p > 0.02 && p < 0.98) {
      const lift = Math.min(1, Math.max(...quads.map((q) => q.bz)) / (W * 0.5));
      ctx.save();
      ctx.beginPath();
      ctx.moveTo(spineX, 6);
      quads.forEach((q) => ctx.lineTo(q.bx + q.bz * 0.45, 6 + q.bz * 0.05));
      for (let k = quads.length - 1; k >= 0; k--) ctx.lineTo(quads[k].bx + quads[k].bz * 0.45, H + quads[k].bz * 0.05);
      ctx.lineTo(spineX, H);
      ctx.closePath();
      ctx.shadowColor = `rgba(0,0,0,${0.32 * lift})`;
      ctx.shadowBlur = 28;
      ctx.shadowOffsetX = 0;
      ctx.fillStyle = `rgba(0,0,0,${0.12 * lift})`;
      ctx.fill();
      ctx.restore();
    }

    // Paint far-to-near so a curl that folds over itself overlaps correctly.
    quads.sort((a, b) => (a.az + a.bz) - (b.az + b.bz));
    for (const q of quads) {
      const a = proj(q.ax, q.az);
      const b = proj(q.bx, q.bz);
      const x0 = Math.min(a.x, b.x);
      const w = Math.abs(b.x - a.x);
      if (w < 0.15) continue;
      const s = (a.s + b.s) / 2;
      const showBack = q.th >= Math.PI / 2;
      const src = showBack ? backCanvas : frontCanvas;
      const pageLeft = showBack
        ? (fwd ? q.i * sw : W - (q.i + 1) * sw)
        : (fwd ? W - (q.i + 1) * sw : q.i * sw);
      const k = sx(src);
      const dy = oy + (0 - oy) * s;
      ctx.drawImage(src, pageLeft * k, 0, sw * k, src.height, x0 - 0.3, dy, w + 0.6, H * s);
      if (q.dA > 0.01 || q.dB > 0.01) {
        // the strip's hinge edge is q.a (nearer the spine); on screen that edge is on the left when the free end is to its right
        const leftIsA = a.x <= b.x;
        const g = ctx.createLinearGradient(x0, 0, x0 + w, 0);
        g.addColorStop(0, `rgba(0,0,0,${leftIsA ? q.dA : q.dB})`);
        g.addColorStop(1, `rgba(0,0,0,${leftIsA ? q.dB : q.dA})`);
        ctx.fillStyle = g;
        ctx.fillRect(x0 - 0.3, dy, w + 0.6, H * s);
      }
    }
  };

  draw(0); // the first frame matches the page it replaces, so swapping it in is invisible
  book.append(cv);
  await nextFrame();
  await new Promise((resolve) => {
    let t0 = null;
    const frame = (now) => {
      if (t0 === null) t0 = now;
      const t = clamp01((now - t0) / FLIP_MS);
      draw(easeSine(t));
      if (t < 1) requestAnimationFrame(frame); else resolve();
    };
    requestAnimationFrame(frame);
  });
  return cv;
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
  let overlay = null;
  if (changed && state.flipAnim && !reducedMotion() && L.spread && old.length === 2 && pages.length === 2 && Math.abs(pages[0] - old[0]) === 2) {
    overlay = await playFlip(old, pages, pages[0] > old[0] ? 1 : -1, L);
    if (token !== renderToken) return; // another page turn started meanwhile
    turned = true;
  }

  reader.innerHTML = `<div class="spread${changed && !turned ? ' fade-in' : ''}">${pages.map(paperHtml).join('')}</div>`;
  $$('.paper', reader).forEach((el) => placePaper(el, L));
  highlightCurrent();
  updateMushafChrome();
  if (overlay) { // the landed page is painted over the real one; fade it away so the swap is invisible
    const spread = $('.spread', reader);
    spread.style.position = 'relative';
    spread.append(overlay);
    requestAnimationFrame(() => { overlay.style.transition = 'opacity 0.2s ease-out'; overlay.style.opacity = '0'; });
    setTimeout(() => overlay.remove(), 320);
  }
  warmNeighbours(pages);
}

// While you read, quietly lay out the pages a turn would reveal so the fit is cached and the fonts are warm.
function warmNeighbours(pages) {
  const L = layoutMushaf();
  const want = L.spread
    ? [...spreadOf(pages[0] + 2), ...spreadOf(Math.max(1, pages[0] - 1))]
    : [pages[0] + 1, pages[0] - 1];
  const todo = [...new Set(want)].filter((p) => p >= 1 && p <= MAX_PAGE);
  const run = () => {
    const holder = document.createElement('div');
    holder.style.cssText = 'position:fixed;left:-99999px;top:0';
    document.body.append(holder);
    Promise.all(todo.map(pageFont)).then(() => {
      todo.forEach((p) => { const el = paperEl(p); holder.append(el); placePaper(el, L); });
      holder.remove();
    });
  };
  (window.requestIdleCallback || ((f) => setTimeout(f, 200)))(run, { timeout: 1500 });
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
