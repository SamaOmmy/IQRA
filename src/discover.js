'use strict';
// Discover tab: today's date and occasions, daily verse / dua / hadith, collections, duas for every moment,
// morning and evening adhkar with counters, the Forty Hadith, the 99 Names and Sunnah fasting.
// Content comes from discover-content.js (curation) and data/discover/*.json (Hisn al-Muslim, adhkar, Arabic hadith).

const discoverStack = [];
let discoverRoute = { page: 'home' };
const adhkarCounts = new Map(); // "key" -> taps so far, for the repeat counters (kept for the session)

const HIJRI_MONTHS = ['Muharram', 'Safar', 'Rabi’ al-Awwal', 'Rabi’ al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha’ban', 'Ramadan', 'Shawwal', 'Dhu al-Qi’dah', 'Dhu al-Hijjah'];
const hijriNumeric = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', { day: 'numeric', month: 'numeric', year: 'numeric' });
const hijriArabic = new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura', { day: 'numeric', month: 'long', year: 'numeric' });

const hisnData = () => data('discover/hisn.json');
const azkarData = () => data('discover/azkar.json');
const nawawiData = () => data('discover/nawawi.json');

function hijriOf(date) {
  const p = {};
  for (const part of hijriNumeric.formatToParts(date)) if (part.type !== 'literal') p[part.type] = +part.value;
  return { d: p.day, m: p.month, y: p.year ?? p.relatedYear };
}

const dayNumber = (date = new Date()) => Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86400000);

// The next date of each calendar occasion, soonest first. Dates follow the Umm al-Qura calendar and can differ by a day from local moon sighting.
function upcomingOccasions(from = new Date()) {
  const found = new Map();
  for (let i = 0; i < 400 && found.size < DISCOVER.occasions.length; i++) {
    const dt = new Date(from.getFullYear(), from.getMonth(), from.getDate() + i, 12);
    const h = hijriOf(dt);
    for (const o of DISCOVER.occasions) {
      if (!found.has(o.name) && o.m === h.m && o.d === h.d) found.set(o.name, { ...o, days: i, date: dt });
    }
  }
  return [...found.values()].sort((a, b) => a.days - b.days);
}

function daysLabel(n) { return n === 0 ? 'Today' : n === 1 ? 'Tomorrow' : `in ${n} days`; }

// ---------- Building blocks ----------
const arabicVerses = (s, a, b) => Array.from({ length: (b || a) - a + 1 }, (_, i) =>
  `${esc(arabicText(s, a + i))} <span class="vno">${toArabicDigits(a + i)}</span>`).join(' ');

function verseBlock([s, a, b], { title = true } = {}) {
  const end = b || a;
  const tr = Array.from({ length: end - a + 1 }, (_, i) => {
    const text = esc(translationText(state.tr1, s, a + i));
    return end > a ? `<sup>${a + i}</sup> ${text}` : text;
  }).join(' ');
  const ref = `${surahOf(s).en} ${s}:${a}${b ? `–${b}` : ''}`;
  return `<article class="vblock" data-s="${s}" data-a="${a}" data-b="${end}">
    ${title ? `<div class="vref"><strong>${esc(ref)}</strong></div>` : ''}
    <div class="v-arabic" dir="rtl">${arabicVerses(s, a, end)}</div>
    <div class="v-trans" dir="${isRtlTranslation(state.tr1) ? 'rtl' : 'ltr'}">${tr}</div>
    <div class="dactions">
      <button class="dbtn" data-dact="read">Read in context</button>
      <button class="dbtn" data-dact="share">Share image</button>
      <button class="dbtn" data-dact="play">▶ Listen</button>
      <button class="dbtn" data-dact="save">☆ Save</button>
      <button class="dbtn" data-dact="copy">Copy</button>
    </div>
  </article>`;
}

function counterHtml(key, count) {
  if (!count || count < 2) return count === 1 ? '<span class="rep">Once</span>' : '';
  const done = adhkarCounts.get(key) || 0;
  return `<button class="counter${done >= count ? ' done' : ''}" data-count="${esc(key)}" data-max="${count}" title="Tap each time you recite it">${done >= count ? '✓ Done' : `${done} / ${count}`}</button>`;
}

function duaBlock({ ar, en, tl, count, src, fadl, title, key }) {
  return `<article class="dua">
    ${title ? `<div class="vref"><strong>${esc(title)}</strong></div>` : ''}
    <div class="dua-ar" dir="rtl">${esc(ar)}</div>
    ${tl ? `<div class="dua-tl">${esc(tl)}</div>` : ''}
    <div class="dua-en">${esc(en)}</div>
    <div class="dua-foot">
      ${key ? counterHtml(key, count) : ''}
      <button class="dbtn" data-dact="copy-dua">Copy</button>
    </div>
    ${(fadl || src) ? `<details class="dua-more"><summary>${fadl ? 'Virtue and source' : 'Source'}</summary>${fadl ? `<p>${esc(fadl)}</p>` : ''}${src ? `<p class="src">${esc(src)}</p>` : ''}</details>` : ''}
  </article>`;
}

function hisnItems(index) {
  const ch = hisnData()[index];
  return ch.items.map((it, i) => duaBlock({ ...it, key: `hisn:${index}:${i}` })).join('');
}

const header = (title, ar, blurb) => `
  <div class="d-head">
    <button class="dbtn back" data-back>‹ Back</button>
    <div><h1>${esc(title)}</h1>${ar ? `<div class="d-head-ar">${esc(ar)}</div>` : ''}</div>
  </div>
  ${blurb ? `<p class="d-blurb">${esc(blurb)}</p>` : ''}`;

const card = (route, title, ar, sub) => `
  <button class="d-card nav" data-go="${esc(route)}">
    ${ar ? `<span class="d-card-ar">${esc(ar)}</span>` : ''}
    <span class="d-card-title">${esc(title)}</span>
    ${sub ? `<span class="d-card-sub">${esc(sub)}</span>` : ''}
  </button>`;

// ---------- Pages ----------
const ICONS = {
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  check: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
  beads: '<circle cx="12" cy="4.5" r="1.9"/><circle cx="18" cy="8" r="1.9"/><circle cx="19" cy="14.5" r="1.9"/><circle cx="14.5" cy="19.5" r="1.9"/><circle cx="8" cy="19" r="1.9"/><circle cx="4.5" cy="13.5" r="1.9"/><circle cx="6.5" cy="7" r="1.9"/>',
  moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5Z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"/>',
  book: '<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3V4Z"/><path d="M9 9h6M9 13h6"/>',
  scroll: '<path d="M3 5.5C5 4.5 8 4.5 12 6.5c4-2 7-2 9-1V19c-2-1-5-1-9 1-4-2-7-2-9-1V5.5Z"/><path d="M12 6.5V20"/>',
  calendar: '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 3v4M15 3v4"/>',
  chart: '<path d="M4 20V11M10 20V4M16 20v-6M22 20H2"/>',
  quiz: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7M12 17h.01"/>',
  bulb: '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10.5c.7.7 1 1.5 1 2.5h6c0-1 .3-1.8 1-2.5A6 6 0 0 0 12 3Z"/>',
  coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.5 1.5 0 0 1 0 3h-3a1.5 1.5 0 0 0 0 3h4"/>',
  star: '<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9L12 3Z"/>',
};
const icon = (n) => `<svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[n]}</svg>`;
const tile = (route, ic, title, sub) => `<button class="q-tile" data-go="${esc(route)}"><span class="ic">${icon(ic)}</span><b>${esc(title)}</b><small>${esc(sub)}</small></button>`;

function greetingFor(now) {
  const h = now.getHours();
  return h < 5 || h >= 21 ? 'Peace be with you tonight' : h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
}

function heroSide(friday) {
  const here = `${surahOf(current.s).en} · verse ${current.a}`;
  let prayer = `<button class="d-hero-btn" data-go="prayer"><small>Prayer times</small><strong>Set your city</strong><span>Times and Qibla, calculated on your computer</span></button>`;
  if (state.loc) {
    const n = nextPrayer(state.loc, { method: state.pmethod, hanafi: state.hanafi });
    const label = PRAYER_NAMES.find((p) => p[0] === n.key)[1];
    prayer = `<button class="d-hero-btn" data-go="prayer"><small>Next prayer</small><strong>${label} <span id="next-time">${timeText(n.at, state.loc.tz)}</span></strong><span id="next-count">in ${countdownText(n.at - new Date())}</span></button>`;
  }
  return `<div class="d-hero-side">
    <button class="d-hero-btn" data-continue><small>Continue reading</small><strong>${esc(here)}</strong><span>Open where you left off</span></button>
    ${prayer}
    ${friday ? `<button class="d-hero-btn" data-go="collection/friday"><small>Jumu’ah Mubarak</small><span>Read Surah al-Kahf and send blessings upon the Prophet ﷺ</span></button>` : ''}
  </div>`;
}

function pageHomeBase() {
  const now = new Date();
  const dn = dayNumber(now);
  const friday = now.getDay() === 5;
  const verse = DISCOVER.dailyVerses[dn % DISCOVER.dailyVerses.length];

  const candidates = [];
  for (const ch of DISCOVER.dailyDuaChapters) hisnData()[ch].items.forEach((it, i) => {
    if (it.ar.length < 230 && it.en.length < 300) candidates.push({ ch, i, it });
  });
  const pick = candidates[dn % candidates.length];
  const hadithN = (dn % 42) + 1;
  const hadithMeta = DISCOVER.nawawi[hadithN];
  const nameOfDay = DISCOVER.names[dn % DISCOVER.names.length];

  const upcoming = upcomingOccasions(now).filter((o) => o.days <= 120).slice(0, 4);
  const chips = [
    ...(friday ? [] : [{ name: 'Jumu’ah (Friday)', days: (5 - now.getDay() + 7) % 7 }]),
    ...upcoming,
  ].sort((a, b) => a.days - b.days).slice(0, 5);

  const h = hijriOf(now);
  const evening = now.getHours() >= 15;
  return `
  <section class="d-hero">
    <div>
      <div class="d-greet">${greetingFor(now)} · السلام عليكم</div>
      <div class="d-hijri-ar">${esc(hijriArabic.format(now))}</div>
      <div class="d-hijri">${h.d} ${HIJRI_MONTHS[h.m - 1]} ${h.y} AH</div>
      <div class="d-greg">${esc(now.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }))}</div>
    </div>
    ${heroSide(friday)}
  </section>

  <nav class="d-jump" aria-label="Sections">
    ${[['today', 'Today'], ['adhkar', 'Adhkar and duas'], ['stories', 'Stories'], ['hadith', 'Hadith'], ['learn', 'Learn']].map(([id, n]) => `<button class="d-chip pick" data-jump="sec-${id}">${n}</button>`).join('')}
  </nav>

  <div class="quick">
    ${tile('prayer', 'clock', 'Prayer times', state.loc ? state.loc.name : 'Times and Qibla')}
    ${tile('salah', 'check', 'Salah tracker', 'Tick off today’s prayers')}
    ${tile('tasbih', 'beads', 'Tasbih', 'A counter for dhikr')}
    ${tile(evening ? 'azkar/evening' : 'azkar/morning', evening ? 'moon' : 'sun', evening ? 'Evening adhkar' : 'Morning adhkar', 'With repeat counters')}
    ${tile('hadith', 'book', 'Hadith library', `${hadithData().length} hadith by theme`)}
    ${tile('shelf/sira', 'scroll', 'The Sira', 'The Prophet’s life, in order')}
    ${tile('calendar', 'calendar', 'Hijri calendar', 'Dates and occasions')}
    ${tile('progress', 'chart', 'Reading progress', 'Goal, streak and khatam')}
    ${tile('quiz', 'quiz', 'Quiz', 'Test what you know')}
    ${tile('learn', 'bulb', 'Guides', 'Wudu, prayer, Hajj and more')}
  </div>

  ${chips.length ? `<div class="d-chips">${chips.map((o) => `<span class="d-chip"><strong>${esc(o.name)}</strong> ${daysLabel(o.days)}</span>`).join('')}</div>` : ''}

  <section class="d-today" id="sec-today">
    <div class="d-col">
      <div class="d-card feature">
        <div class="d-label">Verse of the day</div>
        ${verseBlock(verse)}
      </div>
      <button class="d-card nav d-name-card" data-go="names">
        <div class="d-label">Name of Allah today</div>
        <span class="d-name-ar">${esc(nameOfDay[0])}</span>
        <span class="d-card-title">${esc(nameOfDay[1])}</span>
        <span class="d-card-sub">${esc(nameOfDay[2])}</span>
      </button>
    </div>
    <div class="d-col">
      <div class="d-card">
        <div class="d-label">Dua of the day</div>
        ${duaBlock({ ...pick.it, title: hisnData()[pick.ch].en, key: '' })}
      </div>
      <div class="d-card">
        <div class="d-label">Hadith of the day</div>
        <h3 class="d-h3">${esc(hadithMeta.t)}</h3>
        <p class="d-p">${esc(hadithMeta.s)}</p>
        <p class="src">${esc(hadithMeta.src)}</p>
        <button class="dbtn" data-go="nawawi">Read all forty</button>
      </div>
    </div>
  </section>

  <div id="sec-adhkar"></div>
  <div class="sec-head"><h2 class="d-h2">Adhkar and duas</h2></div>
  <div class="d-grid">
    ${card('azkar/morning', 'Morning adhkar', 'أذكار الصباح', 'With a counter for each repetition')}
    ${card('azkar/evening', 'Evening adhkar', 'أذكار المساء', 'With a counter for each repetition')}
    ${card('daily/prayer', 'After the prayer', 'أذكار بعد الصلاة', 'Tasbih, tahmid and takbir with counters')}
    ${card('daily/sleep', 'Before you sleep', 'أذكار النوم', 'The Prophet’s routine for bedtime')}
    ${DISCOVER.moments.map((m) => card(`moment/${m.id}`, m.title, m.ar, `${m.hisn.length} chapters`)).join('')}
    ${card('hisn-all', 'Hisn al-Muslim', 'حصن المسلم', 'All 132 chapters, searchable')}
  </div>

  <h2 class="d-h2">Collections from the Qur’an and Sunnah</h2>
  <div class="d-grid">${DISCOVER.collections.map((c) => card(`collection/${c.id}`, c.title, c.ar, c.blurb)).join('')}</div>`;
}

function pageCollection(id) {
  const c = DISCOVER.collections.find((x) => x.id === id);
  let n = 0;
  const items = c.items.map((it) => {
    n++;
    if (it.v) return verseBlock(it.v);
    if (it.surah) return `<article class="vblock"><div class="vref"><strong>Surah ${esc(surahOf(it.surah).en)}</strong></div>
      <div class="v-arabic" dir="rtl">سورة ${esc(surahOf(it.surah).ar)}</div>
      <div class="dactions"><button class="dbtn" data-dact="surah" data-s="${it.surah}">Read the whole surah</button><button class="dbtn" data-dact="play-surah" data-s="${it.surah}">▶ Listen</button></div></article>`;
    if (it.dua) return duaBlock({ ...it.dua });
    if (it.hisn != null) return `<h3 class="d-h3">${esc(hisnData()[it.hisn].en)}</h3>${hisnItems(it.hisn)}`;
    return '';
  }).join('');
  return `${header(c.title, c.ar, c.blurb)}
    ${c.facts ? `<div class="d-facts">${c.facts.map((f) => `<blockquote><p>${esc(f.t)}</p><cite>${esc(f.s)}</cite></blockquote>`).join('')}</div>` : ''}
    <div class="d-list">${items}</div>`;
}

function pageMoment(id) {
  const m = DISCOVER.moments.find((x) => x.id === id);
  return `${header(m.title, m.ar, 'From Hisn al-Muslim (Fortress of the Muslim) by Sa’id al-Qahtani.')}
    <div class="d-list">${m.hisn.map((i) => `<details class="d-sec" open><summary><span>${esc(hisnData()[i].en)}</span><span class="d-sec-ar">${esc(hisnData()[i].ar)}</span></summary>${hisnItems(i)}</details>`).join('')}</div>`;
}

function pageHisn(index) {
  const ch = hisnData()[index];
  return `${header(ch.en, ch.ar, 'From Hisn al-Muslim (Fortress of the Muslim) by Sa’id al-Qahtani.')}<div class="d-list">${hisnItems(index)}</div>`;
}

function pageHisnAll() {
  return `${header('Hisn al-Muslim', 'حصن المسلم', 'All 132 chapters of the Fortress of the Muslim.')}
    <input id="hisn-filter" class="input d-filter" type="search" placeholder="Search chapters, e.g. travel, sleep, rain…" autocomplete="off" />
    <div id="hisn-list" class="d-rows">${hisnRows('')}</div>`;
}

function hisnRows(q) {
  const f = q.trim().toLowerCase();
  const rows = hisnData().map((c, i) => ({ c, i })).filter(({ c }) => !f || c.en.toLowerCase().includes(f) || c.ar.includes(f));
  return rows.length ? rows.map(({ c, i }) => `<button class="d-row" data-go="hisn/${i}"><span>${esc(c.en)}</span><span class="d-row-ar">${esc(c.ar)}</span><span class="d-row-n">${c.items.length}</span></button>`).join('')
    : '<p class="empty">No chapters match.</p>';
}

function pageAzkar(type) {
  const morning = type === 'morning';
  const list = azkarData().filter((x) => x.type === 0 || x.type === (morning ? 1 : 2));
  return `${header(morning ? 'Morning adhkar' : 'Evening adhkar', morning ? 'أذكار الصباح' : 'أذكار المساء',
    'Recite after Fajr until sunrise for the morning, and after ‘Asr until sunset for the evening. Tap the counter each time you recite.')}
    <div class="seg d-seg"><button class="seg-btn${morning ? ' active' : ''}" data-go="azkar/morning" data-replace>Morning</button><button class="seg-btn${morning ? '' : ' active'}" data-go="azkar/evening" data-replace>Evening</button></div>
    <div class="d-list">${list.map((x) => duaBlock({ ar: x.ar, en: x.en, tl: x.tl, count: x.count, fadl: x.fadl, src: x.source, key: `azkar:${type}:${x.order}` })).join('')}</div>`;
}

function pageNawawi() {
  const meta = DISCOVER.nawawi;
  return `${header('The Forty Hadith', 'الأربعون النووية', 'Imam Yahya an-Nawawi’s collection of forty-two foundational hadith. The summaries are written for this app; the Arabic is the original text.')}
    <div class="d-list">${nawawiData().map((h) => `<details class="d-hadith"><summary><span class="d-num">${h.n}</span><span class="d-hadith-t">${esc(meta[h.n].t)}</span><span class="d-hadith-src">${esc(meta[h.n].src)}</span></summary>
      <p class="d-p">${esc(meta[h.n].s)}</p>
      <div class="dua-ar" dir="rtl">${esc(h.ar.replace(/<br\s*\/?>/gi, '\n'))}</div>
      <div class="dua-foot"><button class="dbtn" data-dact="copy-hadith" data-n="${h.n}">Copy Arabic</button></div></details>`).join('')}</div>`;
}

function pageNames() {
  const dn = dayNumber() % DISCOVER.names.length;
  return `${header('The 99 Names of Allah', 'أسماء الله الحسنى', '“And to Allah belong the best names, so invoke Him by them.” (Qur’an 7:180)')}
    <div class="d-names">${DISCOVER.names.map(([ar, tl, en], i) => `<div class="d-name${i === dn ? ' today' : ''}"><span class="d-name-n">${i + 1}</span><div class="d-name-ar">${esc(ar)}</div><div class="d-name-tl">${esc(tl)}</div><div class="d-name-en">${esc(en)}</div></div>`).join('')}</div>`;
}

function pageFasting() {
  return `${header('Sunnah fasting', 'صيام التطوع', 'Days when fasting is recommended, with where each is reported.')}
    <div class="d-list">${DISCOVER.fasting.map((f) => `<blockquote class="d-fast"><strong>${esc(f.t)}</strong><p>${esc(f.n)}</p><cite>${esc(f.s)}</cite></blockquote>`).join('')}</div>`;
}

const PAGES = {
  home: () => pageHome(),
  collection: (id) => pageCollection(id),
  moment: (id) => pageMoment(id),
  hisn: (i) => pageHisn(+i),
  'hisn-all': () => pageHisnAll(),
  azkar: (t) => pageAzkar(t),
  nawawi: () => pageNawawi(),
  names: () => pageNames(),
  fasting: () => pageFasting(),
};

function renderDiscover() {
  const { page, arg } = discoverRoute;
  reader.className = 'discover';
  reader.innerHTML = `<div class="disc">${PAGES[page](arg)}
    <p class="d-credit">Duas from Hisn al-Muslim and the morning/evening adhkar database (MIT); Arabic hadith text from the hadith-api project (public domain); summaries and collections written for IQRA. See NOTICE for details.</p></div>`;
  updateLocation();
  if (typeof startPrayerTicker === 'function') startPrayerTicker();
}

function discoverGo(routeString, { replace = false } = {}) {
  const [page, arg] = routeString.split('/');
  if (!replace) discoverStack.push(discoverRoute);
  discoverRoute = { page, arg };
  renderDiscover();
  reader.scrollTop = 0;
}

function discoverBack() {
  if (!discoverStack.length) return false;
  discoverRoute = discoverStack.pop();
  renderDiscover();
  reader.scrollTop = 0;
  return true;
}

function openInReader(s, a) {
  state.view = state.readView === 'verses' ? 'verses' : 'mushaf';
  save();
  applyPrefs();
  navigateTo(s, a);
}

// ---------- Interaction ----------
async function copyText(text, msg = 'Copied') {
  try { await navigator.clipboard.writeText(text); toast(msg); } catch { toast('Could not copy'); }
}

reader.addEventListener('click', (e) => {
  if (state.view !== 'discover') return;
  const go = e.target.closest('[data-go]');
  if (go) { discoverGo(go.dataset.go, { replace: 'replace' in go.dataset }); return; }
  if (e.target.closest('[data-back]')) { discoverBack(); return; }
  if (e.target.closest('[data-continue]')) { openInReader(current.s, current.a); return; }
  const jump = e.target.closest('[data-jump]');
  if (jump) { const t = document.getElementById(jump.dataset.jump); if (t) t.scrollIntoView({ behavior: state.motion === false ? 'auto' : 'smooth', block: 'start' }); return; }

  const counter = e.target.closest('[data-count]');
  if (counter) {
    const key = counter.dataset.count, max = +counter.dataset.max;
    const n = Math.min(max, (adhkarCounts.get(key) || 0) + 1);
    adhkarCounts.set(key, n);
    counter.textContent = n >= max ? '✓ Done' : `${n} / ${max}`;
    counter.classList.toggle('done', n >= max);
    pop(counter);
    if (n >= max) sparkle(counter);
    return;
  }

  const btn = e.target.closest('[data-dact]');
  if (!btn) return;
  const block = btn.closest('.vblock');
  const s = +(btn.dataset.s || block?.dataset.s), a = +(block?.dataset.a || 1), b = +(block?.dataset.b || a);
  switch (btn.dataset.dact) {
    case 'read': openInReader(s, a); break;
    case 'surah': openInReader(s, 1); break;
    case 'play': playVerse(s, a); break;
    case 'play-surah': playVerse(s, 1); break;
    case 'share': openShare(verseShareData(s, a, b)); break;
    case 'save': if (!isBookmarked(s, a)) toggleBookmark(s, a); else toast('Already saved'); break;
    case 'copy': {
      const ar = Array.from({ length: b - a + 1 }, (_, i) => arabicText(s, a + i)).join(' ');
      const en = Array.from({ length: b - a + 1 }, (_, i) => translationText(state.tr1, s, a + i)).join(' ');
      copyText(`${ar}\n\n${en}\n— ${surahOf(s).en} ${s}:${a}${b > a ? `–${b}` : ''}`, 'Verse copied');
      break;
    }
    case 'copy-dua': {
      const d = btn.closest('.dua');
      const parts = ['.dua-ar', '.dua-tl', '.dua-en'].map((q) => d.querySelector(q)?.textContent.trim()).filter(Boolean);
      copyText(parts.join('\n\n'), 'Copied');
      break;
    }
    case 'copy-hadith': copyText(nawawiData().find((h) => h.n === +btn.dataset.n).ar.replace(/<br\s*\/?>/gi, '\n'), 'Hadith copied'); break;
  }
});

reader.addEventListener('input', (e) => {
  if (e.target.id === 'hisn-filter') $('#hisn-list').innerHTML = hisnRows(e.target.value);
});
