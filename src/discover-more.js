'use strict';
// Discover, part two: stories and the Sira, the hadith library, after-prayer and bedtime adhkar, search across everything,
// and saved items. Extends the pages defined in discover.js.

const hadithData = () => data('discover/hadith.json');
const HADITH_THEMES = [
  ['manners', 'Character and manners'], ['mercy', 'Mercy and family'], ['faith', 'Faith and trust in Allah'],
  ['worship', 'Worship and remembrance'], ['knowledge', 'Knowledge and ongoing good'], ['charity', 'Charity and generosity'],
  ['dua', 'Dua and dhikr'], ['family', 'Parents and family'], ['brotherhood', 'Brotherhood and community'],
  ['trade', 'Work and honest dealing'], ['hardship', 'Hardship and the Hereafter'], ['quran', 'The Qur’an'],
];

const isFav = (key) => state.favs.includes(key);
function toggleFav(key) {
  const i = state.favs.indexOf(key);
  if (i >= 0) state.favs.splice(i, 1); else state.favs.unshift(key);
  save();
  return i < 0;
}
const favButton = (key) => `<button class="dbtn${isFav(key) ? ' on' : ''}" data-fav="${esc(key)}" title="Save to your list">${isFav(key) ? '★ Saved' : '☆ Save'}</button>`;

// ---------- Hadith library ----------
function hadithCard(h) {
  return `<article class="dua hadith" data-hadith="${esc(h.id)}">
    <div class="vref"><strong>${esc(h.title)}</strong></div>
    <div class="dua-ar" dir="rtl">${esc(h.ar)}</div>
    <div class="dua-en">${esc(h.en)}</div>
    <p class="src">${esc(h.src)}</p>
    <div class="dua-foot">
      ${favButton('hadith:' + h.id)}
      <button class="dbtn" data-dact="copy-library-hadith">Copy</button>
      <button class="dbtn" data-dact="share-hadith">Share image</button>
    </div>
  </article>`;
}

function pageHadith(theme) {
  const all = hadithData();
  const list = theme ? all.filter((h) => h.theme === theme) : all;
  const title = theme ? HADITH_THEMES.find((t) => t[0] === theme)[1] : 'Hadith library';
  return `${header(title, 'الأحاديث النبوية', 'Hadith from the six major collections, in the original Arabic with a plain English summary. Reports from Bukhari and Muslim are sound; for others, the grading is noted where known. The summaries are written for IQRA; they are not a published translation.')}
    <div class="d-chips filters">
      <button class="d-chip pick${theme ? '' : ' active'}" data-go="hadith" data-replace>All (${all.length})</button>
      ${HADITH_THEMES.map(([id, name]) => `<button class="d-chip pick${theme === id ? ' active' : ''}" data-go="hadith/${id}" data-replace>${esc(name)}</button>`).join('')}
      <button class="d-chip pick" data-go="nawawi">The Forty Hadith</button>
    </div>
    <div class="d-list">${list.map(hadithCard).join('')}</div>`;
}

// ---------- Stories ----------
const storiesOf = (shelf) => {
  const list = DISCOVER.stories.filter((s) => s.shelf === shelf).sort((a, b) => (a.ord ?? a.n ?? 0) - (b.ord ?? b.n ?? 0));
  if (shelf === 'sira') list.forEach((s, i) => { s.n = i + 1; }); // the life of the Prophet is numbered in order
  return list;
};

function storyCard(st) {
  const first = st.p[0].replace(/\s+/g, ' ');
  return `<button class="d-card nav story-card" data-go="story/${esc(st.id)}">
    ${st.ar ? `<span class="d-card-ar">${esc(st.ar)}</span>` : ''}
    <span class="d-card-title">${st.n ? `${st.n}. ` : ''}${esc(st.title)}</span>
    <span class="d-card-era">${st.era ? `${esc(st.era)} · ` : ''}${readingMinutes(st)} min${deepOf(st.id) ? ' · in depth' : ''}</span>
    <span class="d-card-sub">${esc(first.length > 120 ? first.slice(0, 118).replace(/\s+\S*$/, '') + '…' : first)}</span>
  </button>`;
}

function pageShelf(id) {
  const shelf = DISCOVER.shelves.find((s) => s.id === id);
  const list = storiesOf(id);
  return `${header(shelf.title, shelf.ar, shelf.blurb)}
    <p class="d-note">Written for IQRA from the Qur’an, Sahih al-Bukhari, Sahih Muslim and the classical biographies. Where a detail comes from the biographies rather than the two Sahihs, the story says so.</p>
    <div class="d-grid stories">${list.map(storyCard).join('')}</div>`;
}

const deepOf = (id) => (DISCOVER.deep && DISCOVER.deep[id]) || null;
const wordCount = (s) => s.split(/\s+/).filter(Boolean).length;
function readingMinutes(st) {
  const d = deepOf(st.id);
  const n = wordCount(st.p.join(' ')) + (d ? d.s.reduce((a, sec) => a + wordCount(sec.t.join(' ')), 0) : 0);
  return Math.max(1, Math.round(n / 190));
}

function pageStory(id) {
  const st = DISCOVER.stories.find((s) => s.id === id);
  const deep = deepOf(id);
  const shelf = DISCOVER.shelves.find((s) => s.id === st.shelf);
  const list = storiesOf(st.shelf);
  const i = list.findIndex((s) => s.id === id);
  const prev = list[i - 1], next = list[i + 1];
  return `<div class="d-head">
      <button class="dbtn back" data-back>‹ Back</button>
      <div><div class="d-eyebrow"><button class="linklike" data-go="shelf/${esc(shelf.id)}">${esc(shelf.title)}</button>${st.era ? ` · ${esc(st.era)}` : ''} · ${readingMinutes(st)} min read</div>
      <h1>${st.n ? `${st.n}. ` : ''}${esc(st.title)}</h1>${st.ar ? `<div class="d-head-ar">${esc(st.ar)}</div>` : ''}</div>
    </div>
    ${deep && deep.facts ? `<dl class="facts">${deep.facts.map(([k, v]) => `<div><dt>${esc(k)}</dt><dd>${esc(v)}</dd></div>`).join('')}</dl>` : ''}
    <article class="story">
      ${st.p.map((t) => `<p>${esc(t)}</p>`).join('')}
      ${deep ? `<h2 class="d-h2 in-depth">In depth</h2>${deep.s.map((sec) => `<section class="deep"><h3>${esc(sec.h)}</h3>${sec.t.map((t) => `<p>${esc(t)}</p>`).join('')}</section>`).join('')}` : ''}
      <aside class="lessons"><h3>What we can take from it</h3><ul>${st.l.map((t) => `<li>${esc(t)}</li>`).join('')}</ul></aside>
      <p class="src story-src">Source: ${esc(st.src || '')}</p>
      <div class="dactions">${favButton('story:' + st.id)}<button class="dbtn" data-dact="copy-story" data-id="${esc(st.id)}">Copy</button></div>
    </article>
    ${st.v && st.v.length ? `<h2 class="d-h2">From the Qur’an</h2><div class="d-list">${st.v.map((v) => verseBlock(v)).join('')}</div>` : ''}
    <div class="story-nav">
      ${prev ? `<button class="btn" data-go="story/${esc(prev.id)}" data-replace>‹ ${esc(prev.title)}</button>` : '<span></span>'}
      ${next ? `<button class="btn" data-go="story/${esc(next.id)}" data-replace>${esc(next.title)} ›</button>` : '<span></span>'}
    </div>`;
}

// ---------- After prayer and before sleep: dedicated pages with counters ----------
const hisnIndexByTitle = (frag) => hisnData().findIndex((c) => c.en.toLowerCase().includes(frag));
function pageDailyAdhkar(kind) {
  const title = kind === 'prayer' ? 'After the prayer' : 'Before you sleep';
  const ar = kind === 'prayer' ? 'أذكار بعد الصلاة' : 'أذكار النوم';
  const idx = kind === 'prayer' ? hisnIndexByTitle('after completing the prayer') : hisnIndexByTitle('before sleeping');
  return `${header(title, ar, 'From Hisn al-Muslim. Tap the counter each time you recite.')}<div class="d-list">${hisnItems(idx)}</div>`;
}

// ---------- Search across Discover ----------
function discoverSearch(raw) {
  const q = raw.trim().toLowerCase();
  if (q.length < 2) return '';
  const norm = normalizeArabic(raw.trim());
  const hits = [];
  const add = (route, kind, title, snippet) => hits.push({ route, kind, title, snippet });
  const has = (s) => String(s).toLowerCase().includes(q) || (/[؀-ۿ]/.test(raw) && normalizeArabic(String(s)).includes(norm));
  const clip = (t) => (t.length > 130 ? t.slice(0, 128).replace(/\s+\S*$/, '') + '…' : t);

  for (const st of DISCOVER.stories) {
    const dd = deepOf(st.id);
    if (has(st.title) || has(st.ar || '') || st.p.some(has) || st.l.some(has) || (dd && dd.s.some((x) => has(x.h) || x.t.some(has)))) add(`story/${st.id}`, DISCOVER.shelves.find((s) => s.id === st.shelf).title, st.title, clip(st.p[0]));
  }
  for (const h of hadithData()) if (has(h.title) || has(h.en) || has(h.ar)) add(`hadith/${h.theme}`, 'Hadith', h.title, clip(h.en));
  DISCOVER.nawawi.forEach((m, i) => { if (m && (has(m.t) || has(m.s))) add('nawawi', 'Forty Hadith', `${i}. ${m.t}`, clip(m.s)); });
  hisnData().forEach((c, i) => { if (has(c.en) || has(c.ar) || c.items.some((it) => has(it.en) || has(it.ar))) add(`hisn/${i}`, 'Duas (Hisn al-Muslim)', c.en, `${c.items.length} dua${c.items.length > 1 ? 's' : ''}`); });
  DISCOVER.names.forEach(([ar, tl, en]) => { if (has(tl) || has(en) || has(ar)) add('names', 'Names of Allah', tl, en); });
  if (typeof GUIDES !== 'undefined') for (const g of GUIDES) if (has(g.title) || has(g.ar) || has(g.blurb) || g.steps.some((s) => has(s.h) || s.t.some(has))) add(`guide/${g.id}`, 'Guide', g.title, clip(g.blurb));
  for (const c of DISCOVER.collections) if (has(c.title) || has(c.ar) || has(c.blurb)) add(`collection/${c.id}`, 'Collection', c.title, clip(c.blurb));
  if (typeof SURAH_INTROS !== 'undefined') for (const s of Q.surahs) if (has(s.en) || has(s.ar) || has(s.meaning) || has(SURAH_INTROS[s.n] || '')) add('surahs', 'Surah', `${s.n}. ${s.en}`, clip(SURAH_INTROS[s.n] || s.meaning));
  if (!hits.length) return '<p class="empty">Nothing found. Try a name, a place or a topic, such as patience, travel, Yusuf or Badr.</p>';
  return `<div class="d-rows search-results">${hits.slice(0, 40).map((h) => `<button class="d-row" data-go="${esc(h.route)}"><span class="sr-main"><strong>${esc(h.title)}</strong><span class="sr-snip">${esc(h.snippet)}</span></span><span class="d-row-n">${esc(h.kind)}</span></button>`).join('')}</div>${hits.length > 40 ? '<p class="empty">Showing the first 40 results.</p>' : ''}`;
}

// ---------- Saved items ----------
function savedSection() {
  if (!state.favs.length) return '';
  const rows = state.favs.map((k) => {
    const [kind, id] = k.split(':');
    if (kind === 'story') { const s = DISCOVER.stories.find((x) => x.id === id); return s && `<button class="d-row" data-go="story/${esc(id)}"><span>${esc(s.title)}</span><span class="d-row-n">Story</span></button>`; }
    if (kind === 'hadith') { const h = hadithData().find((x) => x.id === id); return h && `<button class="d-row" data-go="hadith/${esc(h.theme)}"><span>${esc(h.title)}</span><span class="d-row-n">Hadith</span></button>`; }
    return '';
  }).filter(Boolean);
  return rows.length ? `<h2 class="d-h2">Your saved items</h2><div class="d-rows">${rows.join('')}</div>` : '';
}

// ---------- Home additions ----------
function storiesHomeSection() {
  const featured = DISCOVER.stories[dayNumber() % DISCOVER.stories.length];
  return `
  <div id="sec-stories"></div>
  <div class="sec-head"><h2 class="d-h2">Stories and the Sira</h2><button class="see-all" data-go="shelf/sira">Start the Sira ›</button></div>
  <div class="story-feature">
    <div class="d-label">Story of the day · ${readingMinutes(featured)} min read</div>
    <h3 class="d-h3">${esc(featured.title)}</h3>
    <p class="d-p">${esc(featured.p[0])}</p>
    <button class="dbtn" data-go="story/${esc(featured.id)}">Read the story</button>
  </div>
  <div class="d-grid shelves">
    ${DISCOVER.shelves.map((s) => card(`shelf/${s.id}`, s.title, s.ar, `${storiesOf(s.id).length} stories`)).join('')}
  </div>`;
}

function hadithHomeSection() {
  const themes = HADITH_THEMES.map(([id, name]) => `<button class="d-chip pick" data-go="hadith/${id}">${esc(name)}</button>`).join('');
  return `
  <div id="sec-hadith"></div>
  <div class="sec-head"><h2 class="d-h2">Hadith</h2><button class="see-all" data-go="hadith">Open the library ›</button></div>
  <div class="d-chips">${themes}</div>
  <div class="d-grid">
    ${card('hadith', 'Hadith library', 'الأحاديث النبوية', `${hadithData().length} hadith with the Arabic, by theme`)}
    ${card('nawawi', 'The Forty Hadith', 'الأربعون النووية', 'Imam an-Nawawi, with a plain summary')}
  </div>`;
}

function learnHomeSection() {
  return `
  <div id="sec-learn"></div>
  <div class="sec-head"><h2 class="d-h2">Learn and reflect</h2></div>
  <div class="d-grid">
    ${card('learn', 'Guides', 'أدلة مبسطة', 'Wudu, the prayer, fasting, Hajj and Umrah, step by step')}
    ${card('surahs', 'About each surah', 'تعريف بالسور', 'A short introduction to all 114 surahs')}
    ${card('names', 'The 99 Names of Allah', 'أسماء الله الحسنى', 'With meanings, and a quiz to learn them')}
    ${card('quiz', 'Quiz', 'اختبر نفسك', 'Names, surahs, stories and the Sira')}
    ${card('fasting', 'Sunnah fasting', 'صيام التطوع', 'Days when fasting is recommended')}
    ${card('zakat', 'Zakat calculator', 'حاسبة الزكاة', 'Work out the zakat due on your savings')}
    ${card('calendar', 'Hijri calendar', 'التقويم الهجري', 'Dates, occasions and Fridays by month')}
    ${card('salah', 'Salah tracker', 'متابعة الصلاة', 'A week of prayers at a glance')}
  </div>`;
}

Object.assign(PAGES, {
  shelf: (id) => pageShelf(id),
  story: (id) => pageStory(id),
  hadith: (theme) => pageHadith(theme),
  daily: (k) => pageDailyAdhkar(k),
});

// ---------- Interaction ----------
reader.addEventListener('click', (e) => {
  if (state.view !== 'discover') return;
  const fav = e.target.closest('[data-fav]');
  if (fav) {
    const on = toggleFav(fav.dataset.fav);
    fav.textContent = on ? '★ Saved' : '☆ Save';
    fav.classList.toggle('on', on);
    toast(on ? 'Saved to your list' : 'Removed from your list');
    return;
  }
  const act = e.target.closest('[data-dact="copy-story"], [data-dact="copy-library-hadith"], [data-dact="share-hadith"]');
  if (!act) return;
  if (act.dataset.dact === 'copy-story') {
    const st = DISCOVER.stories.find((s) => s.id === act.dataset.id);
    const d = deepOf(st.id);
    copyText(`${st.title}\n\n${st.p.join('\n\n')}${d ? '\n\n' + d.s.map((x) => x.h + '\n' + x.t.join('\n\n')).join('\n\n') : ''}\n\nLessons:\n${st.l.map((l) => '- ' + l).join('\n')}\n\nSource: ${st.src || ''}`, 'Story copied');
  } else if (act.dataset.dact === 'share-hadith') {
    const h = hadithData().find((x) => x.id === act.closest('.hadith').dataset.hadith);
    openShare({ ar: h.ar, tr: h.en, ref: h.src.replace(/, narrated by.*$/, '') });
  } else {
    const card = act.closest('.hadith');
    const h = hadithData().find((x) => x.id === card.dataset.hadith);
    copyText(`${h.ar}\n\n${h.en}\n\n${h.src}`, 'Hadith copied');
  }
});
reader.addEventListener('input', (e) => {
  if (e.target.id !== 'discover-search') return;
  const out = $('#discover-results');
  const html = discoverSearch(e.target.value);
  out.innerHTML = html;
  $('#discover-home').hidden = !!html;
});

// The home page: search box, then today, adhkar, stories, hadith, learning and saved items.
function pageHome() {
  return `<input id="discover-search" class="input d-filter d-search" type="search" placeholder="Search stories, hadith, duas, names… e.g. patience, travel, Yusuf" autocomplete="off" />
    <div id="discover-results"></div>
    <div id="discover-home">${pageHomeBase()}${savedSection()}${storiesHomeSection()}${hadithHomeSection()}${learnHomeSection()}</div>`;
}
