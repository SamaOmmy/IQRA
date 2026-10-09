'use strict';
// Features: prayer times and qibla page, reading progress (daily goal, streak, khatam), memorisation mode, verse notes.
// Loaded after discover-more.js so it can add pages to PAGES.

const todayKey = (d = new Date()) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const pad2 = (n) => String(n).padStart(2, '0');

// ---------- Notes ----------
const noteKey = (s, a) => `${s}:${a}`;
const getNote = (s, a) => state.notes[noteKey(s, a)] || '';
function setNote(s, a, text) {
  const k = noteKey(s, a);
  if (text.trim()) state.notes[k] = text; else delete state.notes[k];
  save();
  const mark = $(`.v[data-s="${s}"][data-ayah="${a}"] .v-note`, reader);
  if (mark) mark.hidden = !text.trim();
  if (drawerPanel === 'saved') renderSaved();
}

// ---------- Memorisation mode ----------
function setHifz(on) {
  state.hifz = on;
  save();
  stage.classList.toggle('hifz', on);
  $('#btn-hifz').classList.toggle('on', on);
  $$('.revealed', reader).forEach((el) => el.classList.remove('revealed'));
  if (on) toast('Memorisation mode: click a verse to reveal it. Press H to turn it off.');
}

// Reveal or hide a whole verse; returns true if the click was used for that.
function hifzClick(target) {
  if (!state.hifz || target.closest('button, a, textarea, select')) return false;
  const w = target.closest('.w[data-ayah], .v');
  if (!w) return false;
  const s = w.dataset.s, a = w.dataset.ayah;
  if (w.classList.contains('v')) { w.classList.toggle('revealed'); return false; }
  const words = $$(`.w[data-s="${s}"][data-ayah="${a}"]`, reader);
  const on = !words[0].classList.contains('revealed');
  words.forEach((x) => x.classList.toggle('revealed', on));
  return false; // still select the verse
}

// ---------- Reading progress ----------
function progressData() {
  const rp = state.rp;
  const pagesByDay = (k) => (rp.days[k] ? rp.days[k].length : 0);
  const metGoal = (k) => pagesByDay(k) >= rp.goal;
  // streak: consecutive days meeting the goal, ending today (or yesterday if today is still in progress)
  let streak = 0;
  const d = new Date();
  if (!metGoal(todayKey(d))) d.setDate(d.getDate() - 1);
  while (metGoal(todayKey(d))) { streak++; d.setDate(d.getDate() - 1); }
  const readCount = Object.keys(rp.read).length;
  // pace: average pages per day over the days read in the last 30 days
  const recent = Object.entries(rp.days).filter(([k]) => (Date.now() - new Date(k).getTime()) / 86400e3 <= 30);
  const pace = recent.length ? recent.reduce((n, [, v]) => n + v.length, 0) / Math.max(7, recent.length) : 0;
  const eta = pace > 0 ? new Date(Date.now() + ((604 - readCount) / pace) * 86400e3) : null;
  return { rp, today: pagesByDay(todayKey()), streak, readCount, pace, eta };
}

function markRead(page) {
  const rp = state.rp;
  const day = todayKey();
  const list = (rp.days[day] ||= []);
  if (!list.includes(page)) list.push(page);
  if (!rp.read[page]) {
    rp.read[page] = 1;
    if (Object.keys(rp.read).length >= 604) { rp.khatams++; rp.read = {}; toast('Khatam complete! May Allah accept it from you.'); }
  }
  const keys = Object.keys(rp.days);
  if (keys.length > 400) keys.sort().slice(0, keys.length - 400).forEach((k) => delete rp.days[k]);
  save();
  if (state.view === 'discover' && discoverRoute.page === 'progress') renderDiscover();
}

// A page counts as read after you stay on it for a while with the window in front.
let readTimer = 0;
function scheduleRead(pages) {
  clearTimeout(readTimer);
  readTimer = setTimeout(() => { if (document.hasFocus() && state.view !== 'discover') pages.forEach(markRead); }, 8000);
}

function pageProgress() {
  const p = progressData();
  const goalPct = Math.min(100, Math.round((p.today / p.rp.goal) * 100));
  const cells = Array.from({ length: 604 }, (_, i) => `<i class="pc${p.rp.read[i + 1] ? ' on' : ''}" data-page-go="${i + 1}" title="Page ${i + 1}"></i>`).join('');
  return `${header('Reading progress', 'ورد القراءة', 'Pages count as read when you stay on them for a few seconds in the Mushaf. Everything stays on this computer.')}
    <div class="stat-row">
      <div class="stat"><div class="ring" style="--p:${goalPct}"><span>${p.today}/${p.rp.goal}</span></div><div class="stat-l">Pages today</div></div>
      <div class="stat"><strong class="big">${p.streak}</strong><div class="stat-l">Day streak (goal met)</div></div>
      <div class="stat"><strong class="big">${Math.round((p.readCount / 604) * 100)}%</strong><div class="stat-l">This khatam (${p.readCount} of 604)</div></div>
      <div class="stat"><strong class="big">${p.rp.khatams}</strong><div class="stat-l">Khatams completed</div></div>
    </div>
    <div class="goal-row"><label>Daily goal
      <select id="goal-select" class="input">${[1, 2, 5, 10, 20].map((n) => `<option value="${n}"${n === p.rp.goal ? ' selected' : ''}>${n} page${n > 1 ? 's' : ''}${n === 20 ? ' (one juz)' : ''}</option>`).join('')}</select></label>
      <span class="d-note">${p.eta ? `At your recent pace you would finish around ${p.eta.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}.` : 'Read for a few days and an estimated finish date will appear here.'}</span>
    </div>
    <h2 class="d-h2">Your Qur’an, page by page</h2>
    <div class="khatam-grid">${cells}</div>
    <p class="d-note">Click any square to open that page. <button class="dbtn" id="new-khatam">Start a new khatam</button></p>`;
}

// ---------- Prayer times page ----------
let prayerTicker = 0;
const place = () => state.loc;
const prayerOpts = () => ({ method: state.pmethod, hanafi: state.hanafi });
const timeText = (d, tz) => d.toLocaleTimeString(state.clock24 ? 'en-GB' : 'en-US', { timeZone: tz, hour: state.clock24 ? '2-digit' : 'numeric', minute: '2-digit', hour12: !state.clock24 });
const PRAYER_NAMES = [['fajr', 'Fajr', 'الفجر'], ['sunrise', 'Sunrise', 'الشروق'], ['dhuhr', 'Dhuhr', 'الظهر'], ['asr', 'Asr', 'العصر'], ['maghrib', 'Maghrib', 'المغرب'], ['isha', 'Isha', 'العشاء']];

function countdownText(ms) {
  const m = Math.max(0, Math.round(ms / 60000));
  return m >= 60 ? `${Math.floor(m / 60)}h ${pad2(m % 60)}m` : `${m} min`;
}

function nextChip() {
  if (!state.loc) return `<button class="d-chip pick" data-go="prayer"><strong>Prayer times</strong> Set your city</button>`;
  const n = nextPrayer(place(), prayerOpts());
  const label = PRAYER_NAMES.find((p) => p[0] === n.key)[1];
  return `<button class="d-chip pick" data-go="prayer"><strong>${label}</strong> ${timeText(n.at, place().tz)} · in ${countdownText(n.at - new Date())}</button>`;
}

function qiblaCard() {
  const p = place();
  const b = qiblaBearing(p.lat, p.lon);
  const km = Math.round(distanceToKaabaKm(p.lat, p.lon));
  return `<div class="d-card qibla">
    <div class="d-label">Qibla</div>
    <svg viewBox="-110 -110 220 220" class="compass" aria-label="Qibla compass">
      <circle r="100" class="c-ring"/><circle r="84" class="c-ring thin"/>
      ${[0, 90, 180, 270].map((a) => `<text x="${(Math.sin(rad(a)) * 70).toFixed(1)}" y="${(-Math.cos(rad(a)) * 70 + 5).toFixed(1)}" class="c-card" text-anchor="middle">${['N', 'E', 'S', 'W'][a / 90]}</text>`).join('')}
      <g transform="rotate(${b.toFixed(1)})"><path d="M0 -86 L11 -8 L0 -20 L-11 -8 Z" class="c-arrow"/><circle r="5" class="c-hub"/><path d="M0 -102 l0 6" class="c-tick"/></g>
    </svg>
    <div class="q-line"><strong>${b.toFixed(1)}°</strong> ${compassName(b)} from true north</div>
    <div class="d-note">${km.toLocaleString()} km to the Kaaba. Face this direction measured clockwise from north; a phone compass app or a map helps to find north.</div>
  </div>`;
}

function pagePrayer() {
  const p = place();
  const locBlock = `<div class="d-card loc-card">
    <div class="d-label">Location</div>
    <div class="loc-now">${p ? `<strong>${esc(p.name)}</strong> <span class="d-note">${p.lat.toFixed(2)}°, ${p.lon.toFixed(2)}° · ${esc(p.tz)}</span>` : 'Choose your city. IQRA cannot see your location, so nothing is sent anywhere.'}</div>
    <input id="city-search" class="input" type="search" placeholder="Search a city, e.g. London, Karachi, Toronto…" autocomplete="off" />
    <div id="city-results" class="city-results"></div>
    <details class="custom-loc"><summary>Enter coordinates yourself</summary>
      <div class="row custom-row">
        <input id="c-name" class="input" placeholder="Name" value="My location" />
        <input id="c-lat" class="input" placeholder="Latitude e.g. 51.5" />
        <input id="c-lon" class="input" placeholder="Longitude e.g. -0.12" />
        <input id="c-tz" class="input" placeholder="Time zone" value="${esc(Intl.DateTimeFormat().resolvedOptions().timeZone)}" />
        <button class="btn" id="c-set">Use these</button>
      </div></details>
  </div>`;
  const settings = `<div class="prayer-settings">
    <label>Method <select id="p-method" class="input">${Object.entries(PRAYER_METHODS).map(([k, v]) => `<option value="${k}"${k === state.pmethod ? ' selected' : ''}>${esc(v.name)}</option>`).join('')}</select></label>
    <label>Asr <select id="p-asr" class="input"><option value="0"${state.hanafi ? '' : ' selected'}>Standard (Shafi’i, Maliki, Hanbali)</option><option value="1"${state.hanafi ? ' selected' : ''}>Hanafi</option></select></label>
    <label>Clock <select id="p-clock" class="input"><option value="0"${state.clock24 ? '' : ' selected'}>12-hour</option><option value="1"${state.clock24 ? ' selected' : ''}>24-hour</option></select></label>
    <label class="check"><input type="checkbox" id="p-notify"${state.pnotify ? ' checked' : ''} /> Notify me at prayer times (while IQRA is open)</label>
    <button class="dbtn" data-go="salah">Salah tracker</button>
  </div>`;
  if (!p) return `${header('Prayer times', 'مواقيت الصلاة', 'Computed on your computer from the position of the sun. Estimates: confirm with your local mosque.')}${locBlock}${settings}`;

  const now = new Date();
  const today = localDate(p.tz, now);
  const t = prayerTimes(today, p, prayerOpts());
  const nxt = nextPrayer(p, prayerOpts(), now);
  const h = hijriOf(now);
  return `${header('Prayer times', 'مواقيت الصلاة', 'Computed on your computer from the position of the sun. Estimates: confirm with your local mosque.')}
    <div class="next-hero"><div class="d-label">Next prayer</div><div class="next-name">${PRAYER_NAMES.find((x) => x[0] === nxt.key)[1]} <span id="next-time">${timeText(nxt.at, p.tz)}</span></div><div id="next-count" class="next-count">in ${countdownText(nxt.at - now)}</div>
      <div class="next-date">${esc(p.name)} · ${now.toLocaleDateString('en-GB', { timeZone: p.tz, weekday: 'long', day: 'numeric', month: 'long' })} · ${h.d} ${HIJRI_MONTHS[h.m - 1]} ${h.y} AH</div></div>
    <div class="prayer-grid">
      ${PRAYER_NAMES.map(([k, en, ar]) => `<div class="p-time${k === nxt.key ? ' next' : ''}${k === 'sunrise' ? ' minor' : ''}"><span class="p-ar">${ar}</span><span class="p-en">${en}</span><strong>${timeText(t[k], p.tz)}</strong></div>`).join('')}
    </div>
    <div class="two-col">${qiblaCard()}${locBlock}</div>${settings}
    <p class="d-note">Method and Asr rule change the times by a few minutes. Near the poles in summer, twilight can last all night; IQRA then uses the common one-sixtieth-of-the-night rule.</p>`;
}

function startPrayerTicker() {
  clearInterval(prayerTicker);
  if (state.view !== 'discover' || !['prayer', 'home'].includes(discoverRoute.page)) return;
  prayerTicker = setInterval(() => {
    if (state.view !== 'discover' || !state.loc) { clearInterval(prayerTicker); return; }
    const c = $('#next-count');
    if (c) {
      const n = nextPrayer(place(), prayerOpts());
      c.textContent = `in ${countdownText(n.at - new Date())}`;
      $('#next-time').textContent = timeText(n.at, place().tz);
    }
  }, 20000);
}

function citySearch(q) {
  const k = q.trim().toLowerCase();
  if (k.length < 2) return '';
  const hits = CITIES.filter((c) => c[0].toLowerCase().includes(k) || c[1].toLowerCase().includes(k)).slice(0, 12);
  return hits.length ? hits.map((c) => `<button class="d-row" data-city="${CITIES.indexOf(c)}"><span>${esc(c[0])}</span><span class="d-row-n">${esc(c[1])}</span></button>`).join('') : '<p class="empty">Not in the list. Use “Enter coordinates yourself” below.</p>';
}

function setLocation(loc) {
  state.loc = loc;
  if (state.pmethod === 'auto') state.pmethod = 'mwl';
  save();
  renderDiscover();
}

PAGES.prayer = () => pagePrayer();
PAGES.progress = () => pageProgress();

// ---------- Wiring ----------
reader.addEventListener('click', (e) => {
  const city = e.target.closest('[data-city]');
  if (city) { const c = CITIES[+city.dataset.city]; setLocation({ name: `${c[0]}, ${c[1]}`, lat: c[2], lon: c[3], tz: c[4] }); return; }
  if (e.target.id === 'c-set') {
    const lat = parseFloat($('#c-lat').value), lon = parseFloat($('#c-lon').value), tz = $('#c-tz').value.trim();
    try { new Intl.DateTimeFormat('en', { timeZone: tz }); } catch { toast('That time zone name is not valid (example: Europe/London).'); return; }
    if (!(lat >= -90 && lat <= 90) || !(lon >= -180 && lon <= 180)) { toast('Enter a latitude between -90 and 90 and a longitude between -180 and 180.'); return; }
    setLocation({ name: $('#c-name').value.trim() || 'My location', lat, lon, tz });
    return;
  }
  const pg = e.target.closest('[data-page-go]');
  if (pg) { state.view = 'mushaf'; save(); applyPrefs(); navigateTo(...Object.values(firstVerseOfPage(+pg.dataset.pageGo)), { page: +pg.dataset.pageGo }); return; }
  if (e.target.id === 'new-khatam') {
    if (confirm('Start a new khatam? Your page-by-page progress resets; your daily history and khatam count are kept.')) { state.rp.read = {}; save(); renderDiscover(); }
    return;
  }
  if (state.view !== 'discover') hifzClick(e.target);
}, true);

reader.addEventListener('input', (e) => {
  if (e.target.id === 'city-search') $('#city-results').innerHTML = citySearch(e.target.value);
});
reader.addEventListener('change', (e) => {
  const id = e.target.id;
  if (id === 'goal-select') { state.rp.goal = +e.target.value; save(); renderDiscover(); }
  else if (id === 'p-method') { state.pmethod = e.target.value; save(); renderDiscover(); }
  else if (id === 'p-asr') { state.hanafi = e.target.value === '1'; save(); renderDiscover(); }
  else if (id === 'p-clock') { state.clock24 = e.target.value === '1'; save(); renderDiscover(); }
});

$('#btn-hifz').addEventListener('click', () => setHifz(!state.hifz));
document.addEventListener('keydown', (e) => {
  const tag = document.activeElement.tagName;
  if (/^(INPUT|SELECT|TEXTAREA)$/.test(tag) || e.ctrlKey || e.altKey || e.metaKey) return;
  if (e.key.toLowerCase() === 'h' && state.view !== 'discover') setHifz(!state.hifz);
});

stage.classList.toggle('hifz', state.hifz);
$('#btn-hifz').classList.toggle('on', state.hifz);
