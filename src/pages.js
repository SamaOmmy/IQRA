'use strict';
// Madani mushaf page view: 604 pages, each laid out with the printed line breaks.
// Page data: data/pages/<p>.json = [[surah, ayah, text, line, flags], ...]  flags: 1 = verse-end marker, 2 = first word of verse.

const MAX_PAGE = 604;
const FIT_MAX_FONT = 62;

function pageWords(p) { return data(`pages/${p}.json`); }

function renderPage() {
  const p = Math.min(MAX_PAGE, Math.max(1, state.page));
  state.page = p;
  const words = pageWords(p);

  const lines = new Map();
  for (const w of words) {
    if (!lines.has(w[3])) lines.set(w[3], []);
    lines.get(w[3]).push(w);
  }

  const surahsOnPage = [...new Set(words.map((w) => w[0]))];
  const juz = ayahOf(words[0][0], words[0][1]).juz;
  let html = `<div class="mpage" data-page="${p}">
    <div class="mpage-head"><span>Juz ${juz}</span><span>${surahsOnPage.map((n) => esc(surahOf(n).en)).join(' · ')}</span></div>`;

  for (const lineNo of [...lines.keys()].sort((a, b) => a - b)) {
    const ws = lines.get(lineNo);
    // A surah begins on this line: print its banner (and the Bismillah) first, as the mushaf does.
    for (const w of ws) {
      if ((w[4] & 2) && w[1] === 1) {
        const s = surahOf(w[0]);
        html += `<div class="surah-banner">سورة ${esc(s.ar)}</div>`;
        if (s.n !== 1 && s.n !== 9) html += `<div class="bismillah-line">${esc(Q.bismillah)}</div>`;
      }
    }
    // The last line of a surah is centred, like the printed page.
    const last = ws[ws.length - 1];
    const endsSurah = (last[4] & 1) && last[1] === surahOf(last[0]).ayahs.length;
    html += `<div class="line${p <= 2 ? ' center' : ''}" data-ends-surah="${endsSurah ? 1 : 0}">` + ws.map((w) => (w[4] & 1)
      ? `<span class="mark" data-s="${w[0]}" data-ayah="${w[1]}">${esc(w[2])}</span>`
      : `<span class="w" data-s="${w[0]}" data-ayah="${w[1]}">${esc(w[2])}</span>`).join('') + '</div>';
  }
  html += `<div class="mpage-foot">${toArabicDigits(p)}</div></div>`;

  reader.innerHTML = html;
  fitPage();
  highlightCurrent();
  $('#page-input').value = p;
}

// Choose one font size so the widest printed line exactly fills the page, then centre the short closing lines.
function fitPage() {
  const page = $('.mpage', reader);
  if (!page) return;
  const width = Math.min(state.arSize * 22, reader.clientWidth - 48);
  page.style.width = `${width}px`;
  const cs = getComputedStyle(page);
  const avail = page.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);

  page.classList.add('measuring');
  page.style.setProperty('--mfs', '100px');
  const lineEls = $$('.line', page);
  const natural = lineEls.map((el) => el.getBoundingClientRect().width);
  page.classList.remove('measuring');

  const widest = Math.max(...natural);
  const fs = Math.min(FIT_MAX_FONT, (avail / widest) * 100);
  page.style.setProperty('--mfs', `${fs}px`);
  lineEls.forEach((el, i) => {
    const ratio = (natural[i] * fs) / 100 / avail;
    if (el.dataset.endsSurah === '1' && ratio < 0.85) el.classList.add('center');
  });
}

function goPage(p, { select = true } = {}) {
  p = Math.min(MAX_PAGE, Math.max(1, Math.round(+p) || 1));
  state.page = p;
  if (select) {
    const v = firstVerseOfPage(p);
    current = { s: v.s, a: v.a };
    state.surah = v.s;
    state.ayah = v.a;
    markActiveSurah();
    updateBookmarkButton();
    tafsirRefresh();
    setNowPlayingLabel();
  }
  save();
  renderPage();
  reader.scrollTop = 0;
}

// Highlight every word of the current verse that is on screen (works for pages and for the other views).
function highlightCurrent({ scroll = false } = {}) {
  $$('.current', reader).forEach((el) => el.classList.remove('current'));
  const els = $$(`[data-s="${current.s}"][data-ayah="${current.a}"]`, reader);
  els.forEach((el) => el.classList.add('current'));
  if (scroll && els.length) els[0].scrollIntoView({ block: 'center', behavior: 'smooth' });
}
