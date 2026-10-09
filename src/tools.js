'use strict';
// Tools for Discover: tasbih counter, Hijri calendar, salah tracker, quiz, zakat calculator, guides and the surah index.
// Also the prayer-time notifier, the sleep timer and the keyboard-shortcut sheet.

const shuffle = (a) => { const r = [...a]; for (let i = r.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [r[i], r[j]] = [r[j], r[i]]; } return r; };
const sample = (a, n) => shuffle(a).slice(0, n);

Object.assign(state, {
  tasbih: { i: 0, count: 0, day: '', today: 0, total: 0, sound: false, ...(state.tasbih || {}) },
  salah: state.salah || {},
  quizBest: state.quizBest || {},
});

// ---------- Tasbih ----------
const TASBIH = [
  { ar: 'سُبْحَانَ اللَّهِ', en: 'SubhanAllah', mean: 'Glory be to Allah', n: 33, note: 'The Prophet ﷺ taught saying SubhanAllah 33 times, Alhamdulillah 33 times and Allahu Akbar 34 times after each prayer (Sahih Muslim).' },
  { ar: 'الْحَمْدُ لِلَّهِ', en: 'Alhamdulillah', mean: 'All praise is for Allah', n: 33, note: 'Part of the tasbih after prayer (Sahih Muslim).' },
  { ar: 'اللَّهُ أَكْبَرُ', en: 'Allahu Akbar', mean: 'Allah is the Greatest', n: 34, note: 'Completes the 33, 33, 34 after prayer (Sahih Muslim).' },
  { ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', en: 'SubhanAllahi wa bihamdihi', mean: 'Glory and praise be to Allah', n: 100, note: 'Whoever says it a hundred times in a day, his sins are forgiven even if they are like the foam of the sea (Sahih al-Bukhari and Muslim).' },
  { ar: 'لَا إِلَٰهَ إِلَّا اللَّهُ', en: 'La ilaha illa Allah', mean: 'There is no god but Allah', n: 100, note: 'The Prophet ﷺ said the best remembrance is la ilaha illa Allah (Sunan at-Tirmidhi, hasan).' },
  { ar: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', en: 'La hawla wa la quwwata illa billah', mean: 'There is no power and no strength except with Allah', n: 100, note: 'He called it a treasure from the treasures of Paradise (Sahih al-Bukhari and Muslim).' },
  { ar: 'أَسْتَغْفِرُ اللَّهَ', en: 'Astaghfirullah', mean: 'I seek Allah’s forgiveness', n: 100, note: 'The Prophet ﷺ said he sought Allah’s forgiveness more than seventy times a day (Sahih al-Bukhari).' },
  { ar: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ', en: 'Salawat on the Prophet', mean: 'O Allah, send blessings and peace upon our Prophet Muhammad', n: 100, note: 'Whoever sends one blessing upon me, Allah sends ten upon him (Sahih Muslim).' },
];
let audioCtx = null;
function tick(done) {
  if (!state.tasbih.sound) return;
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    const beep = (freq, at, len) => {
      const o = audioCtx.createOscillator(), g = audioCtx.createGain();
      o.frequency.value = freq; o.type = 'sine';
      g.gain.setValueAtTime(0.0001, audioCtx.currentTime + at);
      g.gain.exponentialRampToValueAtTime(0.08, audioCtx.currentTime + at + 0.01);
      g.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + at + len);
      o.connect(g).connect(audioCtx.destination); o.start(audioCtx.currentTime + at); o.stop(audioCtx.currentTime + at + len + 0.02);
    };
    if (done) { beep(660, 0, 0.12); beep(990, 0.14, 0.2); } else beep(520, 0, 0.05);
  } catch { /* no audio device */ }
}
function tasbihToday() {
  const t = state.tasbih, k = todayKey();
  if (t.day !== k) { t.day = k; t.today = 0; }
  return t;
}
function pageTasbih() {
  const t = tasbihToday(), p = TASBIH[t.i];
  return `${header('Tasbih', 'التسبيح', 'Tap the circle (or press Enter or Space while it is focused) for each repetition. Your count is kept on this computer.')}
  <div class="tasbih-wrap">
    <div class="d-card tasbih-dial">
      <div class="tas-ar" id="tas-ar">${esc(p.ar)}</div>
      <div class="tas-en" id="tas-en">${esc(p.en)} · ${esc(p.mean)}</div>
      <button class="tas-btn" id="tas-btn" data-tool="tap" aria-label="Count"><span><span class="num" id="tas-num">${t.count}</span><small id="tas-of">of ${p.n}</small></span></button>
      <div class="tas-tools">
        <button class="dbtn" data-tool="undo">− One</button>
        <button class="dbtn" data-tool="reset">Reset</button>
        <label class="check"><input type="checkbox" data-tool="sound"${t.sound ? ' checked' : ''} /> Tick sound</label>
      </div>
      <div class="d-note" id="tas-note">${esc(p.note)}</div>
      <div class="d-note" id="tas-stats">Today: <strong>${t.today}</strong> · All time: <strong>${t.total}</strong></div>
    </div>
    <div class="tas-presets">${TASBIH.map((x, i) => `<button class="tas-preset${i === t.i ? ' active' : ''}" data-tool="preset" data-i="${i}"><span><span class="ar">${esc(x.ar)}</span><small>${esc(x.en)}</small></span><small>${x.n}×</small></button>`).join('')}</div>
  </div>`;
}
function refreshTasbih() {
  const t = tasbihToday(), p = TASBIH[t.i];
  const btn = $('#tas-btn');
  if (!btn) return;
  btn.style.setProperty('--p', Math.min(100, (t.count / p.n) * 100));
  $('#tas-num').textContent = t.count;
  $('#tas-of').textContent = t.count >= p.n ? 'complete ✓' : `of ${p.n}`;
  $('#tas-ar').textContent = p.ar;
  $('#tas-en').textContent = `${p.en} · ${p.mean}`;
  $('#tas-note').textContent = p.note;
  $('#tas-stats').innerHTML = `Today: <strong>${t.today}</strong> · All time: <strong>${t.total}</strong>`;
  $$('.tas-preset').forEach((b, i) => b.classList.toggle('active', i === t.i));
}
function tasbihTap() {
  const t = tasbihToday(), p = TASBIH[t.i], btn = $('#tas-btn');
  if (t.count >= p.n) t.count = 0;
  t.count++; t.today++; t.total++;
  save();
  const done = t.count >= p.n;
  tick(done);
  if (btn && motionOn()) {
    const r = document.createElement('span'); r.className = 'tas-ripple'; btn.appendChild(r); setTimeout(() => r.remove(), 650);
    if (done) sparkle(btn, '✦', 8);
  }
  refreshTasbih();
  if (done) toast(`${p.n} complete: ${p.en}`);
}

// ---------- Hijri calendar ----------
let calOffset = 0;
const MONTHS_EN = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const DOW = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
function occasionOn(h) {
  const out = DISCOVER.occasions.filter((o) => o.m === h.m && o.d === h.d).map((o) => ({ name: o.name, note: o.note }));
  if (h.d >= 13 && h.d <= 15 && h.m !== 9 && h.m !== 12 && !(h.m === 10 && h.d === 13)) out.push({ name: 'White day', note: 'The 13th, 14th and 15th of each lunar month are the days of white nights; the Prophet ﷺ advised fasting three days each month (Sahih al-Bukhari and Muslim).', minor: true });
  if (h.m === 12 && h.d >= 11 && h.d <= 13) out.push({ name: 'Days of Tashreeq', note: 'Days of eating, drinking and remembering Allah; fasting is not allowed on them except for pilgrims who have no sacrifice (Sahih Muslim).', minor: true });
  return out;
}
function pageCalendar() {
  const now = new Date();
  const first = new Date(now.getFullYear(), now.getMonth() + calOffset, 1, 12);
  const y = first.getFullYear(), mo = first.getMonth();
  const days = new Date(y, mo + 1, 0).getDate();
  const cells = [];
  const events = [];
  const seenMonths = new Map();
  for (let i = 0; i < first.getDay(); i++) cells.push('<div class="cal-day blank"></div>');
  for (let d = 1; d <= days; d++) {
    const dt = new Date(y, mo, d, 12), h = hijriOf(dt), occ = occasionOn(h);
    if (!seenMonths.has(h.m)) seenMonths.set(h.m, h.y);
    const isToday = dt.toDateString() === now.toDateString();
    occ.filter((o) => !o.minor).forEach((o) => events.push({ d, name: o.name, note: o.note, h }));
    const label = occ.find((o) => !o.minor) || occ[0];
    cells.push(`<div class="cal-day${isToday ? ' today' : ''}${dt.getDay() === 5 ? ' fri' : ''}${h.d === 1 ? ' first-h' : ''}" title="${esc(label ? `${label.name}: ${label.note}` : '')}">
      <span class="cal-g">${d}</span><span class="cal-h">${h.d === 1 ? `${h.d} ${HIJRI_MONTHS[h.m - 1]}` : h.d}</span>
      ${label ? `<span class="cal-ev">${esc(label.name)}</span>` : ''}</div>`);
  }
  const months = [...seenMonths.entries()].map(([m, yr]) => `${HIJRI_MONTHS[m - 1]} ${yr}`);
  return `${header('Hijri calendar', 'التقويم الهجري', 'Dates follow the Umm al-Qura calendar, which can differ by a day from local moon sighting. Fridays are shaded.')}
    <div class="cal-head">
      <button class="dbtn" data-tool="cal" data-d="-1">‹ Previous</button>
      <h2>${MONTHS_EN[mo]} ${y}<small>${esc(months.join(' · '))} AH</small></h2>
      <button class="dbtn" data-tool="cal" data-d="1">Next ›</button>
    </div>
    <div class="cal-grid">${DOW.map((n) => `<div class="cal-dow">${n}</div>`).join('')}${cells.join('')}</div>
    <div class="dactions"><button class="dbtn" data-tool="cal" data-d="0">Today</button></div>
    ${events.length ? `<h2 class="d-h2">Occasions this month</h2><div class="cal-list">${events.map((e) => `<blockquote class="d-fast"><strong>${e.d} ${MONTHS_EN[mo]} · ${e.h.d} ${HIJRI_MONTHS[e.h.m - 1]} · ${esc(e.name)}</strong><p>${esc(e.note)}</p></blockquote>`).join('')}</div>` : ''}
    <h2 class="d-h2">Convert a date</h2>
    <div class="goal-row"><label>Gregorian date <input id="conv-date" class="input" type="date" value="${todayKey()}" /></label><span id="conv-out" class="d-note"></span></div>`;
}
function convertDate() {
  const v = $('#conv-date')?.value;
  if (!v) return;
  const [y, m, d] = v.split('-').map(Number);
  const h = hijriOf(new Date(y, m - 1, d, 12));
  $('#conv-out').textContent = `${d} ${MONTHS_EN[m - 1]} ${y} is ${h.d} ${HIJRI_MONTHS[h.m - 1]} ${h.y} AH`;
}

// ---------- Salah tracker ----------
const SALAH = [['fajr', 'Fajr', 'الفجر'], ['dhuhr', 'Dhuhr', 'الظهر'], ['asr', 'Asr', 'العصر'], ['maghrib', 'Maghrib', 'المغرب'], ['isha', 'Isha', 'العشاء']];
const salahDay = (k) => (state.salah[k] || [false, false, false, false, false]);
function salahStats() {
  const today = new Date();
  let streak = 0;
  for (let i = 0; i < 400; i++) {
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - i);
    const full = salahDay(todayKey(d)).every(Boolean);
    if (full) streak++; else if (i > 0) break;
  }
  const monthKey = todayKey().slice(0, 7);
  let month = 0, total = 0;
  for (const [k, v] of Object.entries(state.salah)) { const c = v.filter(Boolean).length; total += c; if (k.startsWith(monthKey)) month += c; }
  return { streak, month, total };
}
function pageSalah() {
  const k = todayKey(), t = salahDay(k), s = salahStats();
  const times = state.loc ? prayerTimes(new Date(), state.loc, { method: state.pmethod, hanafi: state.hanafi }) : null;
  const week = Array.from({ length: 7 }, (_, i) => new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate() - (6 - i)));
  return `${header('Salah tracker', 'متابعة الصلاة', 'Tick each prayer as you pray it. This is a private reminder between you and Allah; it stays on this computer.')}
    <div class="tracker" id="tracker">${SALAH.map(([key, en, ar], i) => `<button class="t-prayer${t[i] ? ' on' : ''}" data-tool="salah" data-i="${i}"><span class="tick">✓</span><span class="ar">${ar}</span><small>${en}${times ? ` · ${timeText(times[key], state.loc.tz)}` : ''}</small></button>`).join('')}</div>
    <div class="d-note" id="salah-sum">${t.filter(Boolean).length} of 5 prayed today.</div>
    <div class="stat-row">
      <div class="stat"><strong class="big" id="sl-streak">${s.streak}</strong><div class="stat-l">Day streak (all five)</div></div>
      <div class="stat"><strong class="big" id="sl-month">${s.month}</strong><div class="stat-l">Prayers this month</div></div>
      <div class="stat"><strong class="big" id="sl-total">${s.total}</strong><div class="stat-l">Prayers logged in all</div></div>
    </div>
    <h2 class="d-h2">This week</h2>
    <div class="week" id="week">${week.map((d) => { const c = salahDay(todayKey(d)).filter(Boolean).length; return `<div class="d${c === 5 ? ' full' : ''}" data-key="${todayKey(d)}"><b>${c}</b>${DOW[d.getDay()]}</div>`; }).join('')}</div>
    ${state.loc ? '' : '<p class="d-note">Set your city on the <button class="linklike" data-go="prayer"><u>prayer times page</u></button> to see each prayer’s time here.</p>'}`;
}
function refreshSalah() {
  const k = todayKey(), t = salahDay(k), s = salahStats();
  $$('#tracker .t-prayer').forEach((b, i) => b.classList.toggle('on', !!t[i]));
  $('#salah-sum').textContent = `${t.filter(Boolean).length} of 5 prayed today.`;
  $('#sl-streak').textContent = s.streak; $('#sl-month').textContent = s.month; $('#sl-total').textContent = s.total;
  const d = $(`#week [data-key="${k}"]`);
  if (d) { d.firstChild.textContent = t.filter(Boolean).length; d.classList.toggle('full', t.every(Boolean)); }
}

// ---------- Quiz ----------
const BASICS = [
  ['How many pillars does Islam have?', ['Five', 'Four', 'Six', 'Seven'], 'The testimony of faith, prayer, zakat, fasting Ramadan and Hajj (Sahih al-Bukhari and Muslim).'],
  ['How many obligatory rak’ahs does the Fajr prayer have?', ['Two', 'Three', 'Four', 'Five'], 'Fajr is two rak’ahs; Maghrib three; Dhuhr, Asr and Isha four each.'],
  ['How many obligatory rak’ahs does Maghrib have?', ['Three', 'Two', 'Four', 'Five'], 'Maghrib is the three-rak’ah prayer.'],
  ['Which surah was the first to be revealed, in its opening verses?', ['Al-‘Alaq', 'Al-Fatiha', 'Al-Baqarah', 'Al-Muddaththir'], '“Read in the name of your Lord who created” (96:1) began the revelation in the cave of Hira.'],
  ['Which is the longest surah of the Qur’an?', ['Al-Baqarah', 'Al-Imran', 'An-Nisa', 'Al-A‘raf'], 'Al-Baqarah has 286 verses.'],
  ['Which is the shortest surah?', ['Al-Kawthar', 'Al-Ikhlas', 'Al-‘Asr', 'An-Nasr'], 'Al-Kawthar has three short verses.'],
  ['Which surah has no “Bismillah” at its beginning?', ['At-Tawbah', 'Al-Anfal', 'Yunus', 'Al-Ma’idah'], 'Surah At-Tawbah (9) is the one surah that does not begin with it.'],
  ['Which surah contains the Bismillah twice?', ['An-Naml', 'Al-Kahf', 'Maryam', 'Ta-Ha'], 'An-Naml 27:30 quotes the letter of Sulayman, which begins with it.'],
  ['In which month is fasting obligatory?', ['Ramadan', 'Muharram', 'Sha’ban', 'Dhul Hijjah'], 'Ramadan, the ninth month (2:185).'],
  ['In which surah is Laylat al-Qadr named?', ['Al-Qadr', 'Ad-Dukhan', 'Al-Baqarah', 'Al-‘Alaq'], 'Surah Al-Qadr (97): “better than a thousand months”.'],
  ['Who was the first mu’adhdhin of Islam?', ['Bilal ibn Rabah', 'Abu Bakr', '‘Umar ibn al-Khattab', 'Khalid ibn al-Walid'], 'Bilal, the Prophet’s mu’adhdhin in Madinah.'],
  ['In which cave did the Prophet ﷺ receive the first revelation?', ['Hira', 'Thawr', 'Uhud', 'Al-Kahf'], 'He used to retire to the cave of Hira on Jabal al-Nur.'],
  ['Which prophet built the Ka‘bah with his son Isma‘il?', ['Ibrahim', 'Nuh', 'Musa', 'Adam'], '“And when Ibrahim raised the foundations of the House with Isma‘il” (2:127).'],
  ['Which prophet was swallowed by a great fish?', ['Yunus', 'Ayyub', 'Idris', 'Hud'], 'He called out in the darkness: “There is no god but You, glory be to You” (21:87).'],
  ['To which prophet was the Torah (Tawrah) given?', ['Musa', 'Dawud', 'Isa', 'Ibrahim'], 'Musa, the Zabur to Dawud and the Injil to ‘Isa.'],
  ['Which angel brought the revelation to the prophets?', ['Jibril', 'Mika’il', 'Israfil', 'Malik'], 'Jibril (Gabriel).'],
  ['Which Companion was given the title “Sword of Allah”?', ['Khalid ibn al-Walid', 'Hamzah', '‘Ali', 'Sa‘d ibn Abi Waqqas'], 'The Prophet ﷺ called Khalid “a sword among the swords of Allah” (Sahih al-Bukhari).'],
  ['Who was the first wife of the Prophet ﷺ?', ['Khadijah', '‘A’ishah', 'Hafsah', 'Zaynab'], 'Khadijah bint Khuwaylid, the first to believe in him.'],
  ['Who was the first caliph after the Prophet ﷺ?', ['Abu Bakr', '‘Umar', '‘Uthman', '‘Ali'], 'Abu Bakr as-Siddiq.'],
  ['Which Companion is known as al-Faruq?', ['‘Umar ibn al-Khattab', 'Abu Bakr', '‘Uthman', 'Abu ‘Ubaydah'], '“The one who distinguishes truth from falsehood”.'],
  ['In which city did the Prophet ﷺ spend the last ten years of his life?', ['Madinah', 'Makkah', 'Ta’if', 'Jerusalem'], 'After the Hijrah in the year 622 CE.'],
  ['Which battle took place in the second year after the Hijrah?', ['Badr', 'Uhud', 'The Trench', 'Hunayn'], 'Badr, in Ramadan of 2 AH.'],
  ['Towards what direction do Muslims pray?', ['The Ka‘bah in Makkah', 'Al-Aqsa in Jerusalem', 'The Prophet’s Mosque', 'The east'], 'The qibla was changed from Jerusalem to the Ka‘bah (2:144).'],
  ['What is the Qur’an’s opening surah called?', ['Al-Fatiha', 'Al-Baqarah', 'Al-Ikhlas', 'Yasin'], 'Al-Fatiha, “The Opening”, with seven verses.'],
  ['How many verses does Surah Al-Fatiha have?', ['Seven', 'Five', 'Six', 'Eight'], 'It is “the seven oft-repeated verses” (15:87).'],
  ['What is zakat al-fitr given at the end of?', ['Ramadan', 'Hajj', 'The year', 'Shawwal'], 'It is given before the Eid prayer, to purify the fast and feed the poor.'],
  ['Which prophet is known as Khalilullah, the close friend of Allah?', ['Ibrahim', 'Musa', 'Nuh', 'Muhammad'], 'Allah “took Ibrahim as a close friend” (4:125).'],
  ['What is the Arabic word for the pilgrimage to Makkah?', ['Hajj', 'Umrah', 'Zakat', 'Sawm'], 'Hajj is performed in Dhul Hijjah; Umrah can be performed at any time.'],
  ['What does “Islam” mean at its root?', ['Submission and peace', 'Strength', 'Knowledge', 'Gathering'], 'From the root s-l-m: submission to Allah, and peace.'],
  ['Which surah is recommended to be read on Friday?', ['Al-Kahf', 'Al-Waqi‘ah', 'Ar-Rahman', 'Al-Mulk'], 'Whoever reads Surah al-Kahf on Friday will have a light between the two Fridays (as reported by al-Hakim and others).'],
];
const quiz = { qs: [], i: 0, score: 0, mode: 'mixed', locked: false };
const maskTitle = (sentence, title) => {
  const stop = new Set(['the', 'and', 'prophet', 'story', 'of', 'in', 'with', 'his', 'her', 'a', 'to', 'from']);
  const words = title.split(/[^A-Za-z‘’'’-]+/).filter((w) => w.length > 3 && !stop.has(w.toLowerCase()));
  let out = sentence;
  for (const w of words) out = out.replace(new RegExp(w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi'), '…');
  return out;
};
function makeOptions(correct, pool, n = 4) {
  const others = shuffle(pool.filter((x) => x !== correct)).slice(0, n - 1);
  const opts = shuffle([correct, ...others]);
  return { opts, a: opts.indexOf(correct) };
}
const QUIZ_MAKERS = {
  names() {
    const [ar, tl, en] = DISCOVER.names[Math.floor(Math.random() * DISCOVER.names.length)];
    const pool = DISCOVER.names.map((n) => n[2]);
    const { opts, a } = makeOptions(en, [...new Set(pool)]);
    return { q: 'What does this Name of Allah mean?', ar, sub: tl, opts, a, why: `${tl} means “${en}”.` };
  },
  surahs() {
    const S2 = Q.surahs, s = S2[Math.floor(Math.random() * 114)], kind = Math.floor(Math.random() * 4);
    if (kind === 0) { const { opts, a } = makeOptions(s.en, S2.map((x) => x.en)); return { q: `Which surah is number ${s.n} in the Qur’an?`, opts, a, why: `Surah ${s.n} is ${s.en} (${s.meaning}).` }; }
    if (kind === 1) {
      const n = s.ayahs.length, set = new Set([n]);
      while (set.size < 4) set.add(Math.max(3, n + Math.floor(Math.random() * 21) - 10));
      const { opts, a } = makeOptions(String(n), [...set].map(String));
      return { q: `How many verses does Surah ${s.en} have?`, opts, a, why: `${s.en} has ${n} verses.` };
    }
    if (kind === 2) { const { opts, a } = makeOptions(s.type === 'Meccan' ? 'Makkah' : 'Madinah', ['Makkah', 'Madinah']); return { q: `Was Surah ${s.en} revealed mainly in Makkah or in Madinah?`, opts, a, why: `${s.en} is classed as ${s.type === 'Meccan' ? 'Makkan' : 'Madinan'}.` }; }
    const { opts, a } = makeOptions(s.meaning, S2.map((x) => x.meaning));
    return { q: `What does the name of Surah ${s.en} mean?`, ar: s.ar, opts, a, why: `${s.en}: “${s.meaning}”.` };
  },
  basics() {
    const [q, o, why] = BASICS[Math.floor(Math.random() * BASICS.length)];
    const opts = shuffle(o);
    return { q, opts, a: opts.indexOf(o[0]), why };
  },
  stories() {
    const st = DISCOVER.stories[Math.floor(Math.random() * DISCOVER.stories.length)];
    const sentences = st.p[0].split(/(?<=[.!?])\s+/);
    let clue = sentences[0];
    if (clue.length < 70 && sentences[1]) clue += ' ' + sentences[1];
    clue = maskTitle(clue, st.title);
    const same = DISCOVER.stories.filter((x) => x.shelf === st.shelf).map((x) => x.title);
    const { opts, a } = makeOptions(st.title, same.length >= 4 ? same : DISCOVER.stories.map((x) => x.title));
    return { q: 'Which story begins like this?', clue, opts, a, why: `This is “${st.title}”, in the Stories section.` };
  },
};
function buildQuiz(mode) {
  const kinds = mode === 'mixed' ? ['names', 'surahs', 'basics', 'stories', 'basics', 'surahs', 'names', 'basics', 'stories', 'surahs'] : Array(10).fill(mode);
  const seen = new Set(), qs = [];
  for (const k of kinds) {
    for (let tries = 0; tries < 12; tries++) {
      const q = QUIZ_MAKERS[k]();
      if (!seen.has(q.q + (q.ar || '') + (q.clue || ''))) { seen.add(q.q + (q.ar || '') + (q.clue || '')); qs.push(q); break; }
    }
  }
  return qs;
}
function pageQuiz() {
  return `${header('Quiz', 'اختبر نفسك', 'Ten questions at a time. Choose a topic, or mix them all.')}
    <div class="d-chips">${[['mixed', 'Mixed'], ['names', 'Names of Allah'], ['surahs', 'Surahs'], ['basics', 'Basics and the Sira'], ['stories', 'Stories']].map(([id, n]) => `<button class="d-chip pick${quiz.mode === id ? ' active' : ''}" data-tool="quiz-start" data-mode="${id}">${n}${state.quizBest[id] != null ? ` · best ${state.quizBest[id]}/10` : ''}</button>`).join('')}</div>
    <div class="quiz-card d-card" id="quiz-box"></div>`;
}
function quizIntro() {
  $('#quiz-box').innerHTML = `<div class="quiz-q">Ready?</div><p class="d-note">Pick a topic above to begin. The questions come from the Names of Allah, the surahs, the stories and the basics of the faith.</p>`;
}
function quizRender() {
  const q = quiz.qs[quiz.i], box = $('#quiz-box');
  if (!box) return;
  if (!q) {
    const best = Math.max(state.quizBest[quiz.mode] || 0, quiz.score);
    state.quizBest[quiz.mode] = best; save();
    const msg = quiz.score >= 9 ? 'Excellent, mashaAllah.' : quiz.score >= 6 ? 'Good work. Keep learning.' : 'Every question teaches something. Try again.';
    box.innerHTML = `<div class="d-label">Finished</div><div class="quiz-score">${quiz.score}</div><div class="quiz-q">out of ${quiz.qs.length}</div><p class="d-note">${msg} Best: ${best}/10.</p><div class="dactions" style="justify-content:center"><button class="btn primary" data-tool="quiz-start" data-mode="${quiz.mode}">Play again</button></div>`;
    countUp();
    if (quiz.score >= 8) sparkle(box, '✦', 10);
    return;
  }
  box.innerHTML = `<div class="quiz-meter"><i style="width:${(quiz.i / quiz.qs.length) * 100}%"></i></div>
    <div class="d-label" style="margin-top:12px">Question ${quiz.i + 1} of ${quiz.qs.length}</div>
    ${q.ar ? `<div class="quiz-ar" dir="rtl">${esc(q.ar)}</div>` : ''}
    <div class="quiz-q">${esc(q.q)}</div>
    ${q.clue ? `<blockquote>${esc(q.clue)}</blockquote>` : ''}
    <div class="quiz-opts">${q.opts.map((o, i) => `<button class="quiz-opt" data-tool="answer" data-i="${i}">${esc(o)}</button>`).join('')}</div>
    <div class="quiz-why" id="quiz-why"></div>`;
  quiz.locked = false;
}
function quizAnswer(i) {
  if (quiz.locked) return;
  quiz.locked = true;
  const q = quiz.qs[quiz.i];
  $$('.quiz-opt').forEach((b, k) => { b.disabled = true; if (k === q.a) b.classList.add('right'); else if (k === i) b.classList.add('wrong'); });
  if (i === q.a) quiz.score++;
  $('#quiz-why').innerHTML = `${esc(q.why)} <button class="dbtn" data-tool="next-q">${quiz.i + 1 >= quiz.qs.length ? 'See score' : 'Next ›'}</button>`;
}

// ---------- Zakat ----------
function pageZakat() {
  const f = (id, label, ph = '0') => `<label>${label}<input class="input zk" id="${id}" type="number" min="0" step="any" placeholder="${ph}" inputmode="decimal" /></label>`;
  return `${header('Zakat calculator', 'حاسبة الزكاة', 'A simple estimate of the zakat due on savings. Enter all amounts in the same currency.')}
    <div class="d-card"><div class="d-label">Your wealth</div>
      <div class="zakat-grid">${f('zk-cash', 'Cash, bank and savings')}${f('zk-gold', 'Gold and silver (market value)')}${f('zk-invest', 'Investments and shares (market value)')}${f('zk-biz', 'Business stock for sale')}${f('zk-owed', 'Money owed to you that you expect back')}${f('zk-debt', 'Debts you must pay soon (subtract)')}</div>
      <div class="d-label" style="margin-top:12px">Nisab</div>
      <div class="zakat-grid">${f('zk-gprice', 'Price of 1 gram of gold')}${f('zk-sprice', 'Price of 1 gram of silver')}
      <label>Nisab measured by<select class="input zk" id="zk-std"><option value="silver">Silver, 595 g (lower threshold)</option><option value="gold">Gold, 85 g</option></select></label></div>
    </div>
    <div class="d-card zakat-result" id="zk-out" style="margin-top:12px">Enter your figures above.</div>
    <p class="d-note">Zakat is 2.5% of the net wealth that you have held above the nisab for a full lunar year. Scholars differ on details such as which standard to use, jewellery for personal use and pensions. This is an aid, not a ruling: please ask a trusted scholar about your case.</p>`;
}
function zakatCalc() {
  const v = (id) => parseFloat($('#' + id)?.value) || 0;
  const net = v('zk-cash') + v('zk-gold') + v('zk-invest') + v('zk-biz') + v('zk-owed') - v('zk-debt');
  const std = $('#zk-std').value;
  const nisab = std === 'gold' ? v('zk-gprice') * 85 : v('zk-sprice') * 595;
  const out = $('#zk-out');
  const fmt = (n) => n.toLocaleString(undefined, { maximumFractionDigits: 2 });
  if (!nisab) { out.innerHTML = `Net wealth: <strong>${fmt(net)}</strong><br>Enter today’s price of ${std} per gram to see whether you are above the nisab.`; return; }
  out.innerHTML = net >= nisab
    ? `Net wealth <strong>${fmt(net)}</strong> is above the nisab of ${fmt(nisab)}.<br>Zakat due: <strong>${fmt(net * 0.025)}</strong>`
    : `Net wealth <strong>${fmt(net)}</strong> is below the nisab of ${fmt(nisab)}, so zakat is not due on it.`;
}

// ---------- Guides and the surah index ----------
const guideList = () => (typeof GUIDES !== 'undefined' ? GUIDES : []);
function pageLearn() {
  return `${header('Guides', 'أدلة مبسطة', 'Plain step-by-step guides. The schools of fiqh differ in some details, so the notes point out where. For your own case, ask a scholar you trust.')}
    <div class="d-grid">${guideList().map((g) => card(`guide/${g.id}`, g.title, g.ar, g.blurb)).join('')}
      ${card('zakat', 'Zakat calculator', 'حاسبة الزكاة', 'Work out the zakat due on your savings')}</div>`;
}
function pageGuide(id) {
  const g = guideList().find((x) => x.id === id);
  if (!g) return `${header('Guide', '', 'This guide was not found.')}`;
  return `${header(g.title, g.ar, g.blurb)}
    <ol class="guide-steps">${g.steps.map((s) => `<li><h3>${esc(s.h)}</h3>${s.t.map((p) => `<p>${esc(p)}</p>`).join('')}${s.ar ? `<div class="ar" dir="rtl">${esc(s.ar)}</div>` : ''}${s.verses ? `<div class="ar" dir="rtl">${arabicVerses(...s.verses)}</div><p class="tl">${esc(Array.from({ length: s.verses[2] - s.verses[1] + 1 }, (_, i) => translationText(state.tr1, s.verses[0], s.verses[1] + i)).join(' '))} (${s.verses[0]}:${s.verses[1]}${s.verses[2] > s.verses[1] ? '–' + s.verses[2] : ''})</p>` : ''}${s.tl ? `<p class="tl">${esc(s.tl)}</p>` : ''}${s.en ? `<p>${esc(s.en)}</p>` : ''}</li>`).join('')}</ol>
    ${g.notes ? `<div class="lessons"><h3>Good to know</h3><ul>${g.notes.map((n) => `<li>${esc(n)}</li>`).join('')}</ul></div>` : ''}
    <p class="src">${esc(g.src || '')}</p>`;
}
function surahRow(s) {
  const intro = (typeof SURAH_INTROS !== 'undefined' && SURAH_INTROS[s.n]) || '';
  return `<details class="d-hadith surah-row" data-q="${esc((s.en + ' ' + s.meaning + ' ' + s.n + ' ' + intro).toLowerCase())}">
    <summary><span class="d-num">${s.n}</span><span class="d-hadith-t">${esc(s.en)} <span class="d-sec-ar">${esc(s.ar)}</span></span><span class="d-hadith-src">${esc(s.meaning)} · ${s.ayahs.length} verses · ${s.type === 'Meccan' ? 'Makkan' : 'Madinan'}</span></summary>
    <p class="d-p">${esc(intro) || 'Introduction coming soon.'}</p>
    <div class="dactions"><button class="dbtn" data-dact="surah" data-s="${s.n}">Read it</button><button class="dbtn" data-dact="play" data-s="${s.n}">▶ Listen</button></div>
  </details>`;
}
function pageSurahs() {
  return `${header('About each surah', 'تعريف بالسور', 'A short introduction to every surah: its name, where it was revealed, and what it speaks about.')}
    <input id="surah-search" class="input d-filter" type="search" placeholder="Filter by name, meaning or topic…" autocomplete="off" />
    <div id="surah-rows">${Q.surahs.map(surahRow).join('')}</div>`;
}

Object.assign(PAGES, {
  tasbih: pageTasbih, calendar: pageCalendar, salah: pageSalah, quiz: pageQuiz, zakat: pageZakat,
  learn: pageLearn, guide: (id) => pageGuide(id), surahs: pageSurahs,
});

// ---------- Interaction ----------
reader.addEventListener('click', (e) => {
  if (state.view !== 'discover') return;
  const el = e.target.closest('[data-tool]');
  if (!el) return;
  switch (el.dataset.tool) {
    case 'tap': tasbihTap(); break;
    case 'undo': { const t = tasbihToday(); if (t.count > 0) { t.count--; t.today = Math.max(0, t.today - 1); t.total = Math.max(0, t.total - 1); save(); refreshTasbih(); } break; }
    case 'reset': { tasbihToday().count = 0; save(); refreshTasbih(); break; }
    case 'preset': { const t = tasbihToday(); t.i = +el.dataset.i; t.count = 0; save(); refreshTasbih(); break; }
    case 'cal': calOffset = el.dataset.d === '0' ? 0 : calOffset + +el.dataset.d; renderDiscover(); break;
    case 'salah': {
      const k = todayKey(), arr = [...salahDay(k)];
      arr[+el.dataset.i] = !arr[+el.dataset.i];
      state.salah[k] = arr; save(); refreshSalah();
      if (arr[+el.dataset.i]) { pop(el.querySelector('.tick')); if (arr.every(Boolean)) { sparkle(el, '✦', 8); toast('All five prayers today. May Allah accept them.'); } }
      break;
    }
    case 'quiz-start': quiz.mode = el.dataset.mode; quiz.qs = buildQuiz(quiz.mode); quiz.i = 0; quiz.score = 0; $$('[data-tool="quiz-start"]').forEach((b) => b.classList.toggle('active', b === el)); quizRender(); break;
    case 'answer': quizAnswer(+el.dataset.i); break;
    case 'next-q': quiz.i++; quizRender(); break;
    default:
  }
});
reader.addEventListener('change', (e) => {
  if (state.view !== 'discover') return;
  if (e.target.dataset?.tool === 'sound') { state.tasbih.sound = e.target.checked; save(); }
  if (e.target.id === 'conv-date') convertDate();
  if (e.target.id === 'zk-std') zakatCalc();
  if (e.target.id === 'p-notify') setPrayerNotify(e.target.checked).then((on) => { e.target.checked = on; });
});
reader.addEventListener('input', (e) => {
  if (state.view !== 'discover') return;
  if (e.target.classList?.contains('zk')) zakatCalc();
  if (e.target.id === 'surah-search') {
    const q = e.target.value.trim().toLowerCase();
    $$('#surah-rows .surah-row').forEach((r) => { r.hidden = !!q && !r.dataset.q.includes(q); });
  }
});

// quiz intro, date converter and tasbih focus after a page renders
const renderDiscoverWithTools = renderDiscover;
renderDiscover = function renderDiscoverToolsHook() {
  renderDiscoverWithTools();
  if (discoverRoute.page === 'quiz') quizIntro();
  if (discoverRoute.page === 'calendar') convertDate();
  if (discoverRoute.page === 'zakat') zakatCalc();
  if (discoverRoute.page === 'tasbih') refreshTasbih();
};

// ---------- Prayer-time notifications ----------
const notified = new Set();
function checkPrayerNotify() {
  if (!state.pnotify || !state.loc || typeof Notification === 'undefined' || Notification.permission !== 'granted') return;
  const now = new Date();
  const times = prayerTimes(now, state.loc, { method: state.pmethod, hanafi: state.hanafi });
  for (const [key, en, ar] of PRAYER_NAMES) {
    if (key === 'sunrise') continue;
    const at = times[key], id = `${todayKey()}:${key}`;
    if (at && now >= at && now - at < 90000 && !notified.has(id)) {
      notified.add(id);
      new Notification(`${en}: time for prayer`, { body: `${ar} · ${timeText(at, state.loc.tz)} in ${state.loc.name}`, silent: false });
    }
  }
}
setInterval(checkPrayerNotify, 20000);
async function setPrayerNotify(on) {
  if (on && typeof Notification !== 'undefined' && Notification.permission !== 'granted') {
    const r = await Notification.requestPermission();
    if (r !== 'granted') { state.pnotify = false; save(); toast('Notifications are blocked for IQRA in Windows settings'); return false; }
  }
  state.pnotify = on; save();
  toast(on ? 'You will be notified at each prayer time while IQRA is open' : 'Prayer notifications are off');
  return on;
}

// ---------- Sleep timer ----------
let sleepTimer = 0;
$('#sleep').addEventListener('change', (e) => {
  clearTimeout(sleepTimer);
  const min = +e.target.value;
  if (!min) return;
  sleepTimer = setTimeout(() => { audio.pause(); $('#sleep').value = '0'; toast('Sleep timer: audio stopped'); }, min * 60000);
  toast(`Audio will stop in ${min} minutes`);
});

// ---------- Keyboard shortcut sheet ----------
const SHORTCUTS = [['Ctrl K', 'Jump to a surah, verse, page or juz'], ['← →', 'Turn the page'], ['Space', 'Play or pause'], ['N / P', 'Next or previous verse'], ['B', 'Save the selected verse'], ['T', 'Study panel'], ['H', 'Memorisation mode'], ['Ctrl F', 'Search'], ['Ctrl L', 'Library'], ['Ctrl + / −', 'Zoom'], ['?', 'This sheet'], ['Esc', 'Close the open panel']];
function toggleHelp() {
  let w = $('#help-wrap');
  if (w) { w.remove(); return; }
  w = document.createElement('div');
  w.id = 'help-wrap';
  w.innerHTML = `<div class="modal-card" role="dialog" aria-label="Keyboard shortcuts"><div class="modal-head"><strong>Keyboard shortcuts</strong><button class="icon-btn" aria-label="Close" id="help-close">✕</button></div><div class="modal-body"><div class="kbd-grid">${SHORTCUTS.map(([k, d]) => `<span>${k.split(' ').map((x) => `<kbd>${x}</kbd>`).join(' ')}</span><span>${d}</span>`).join('')}</div></div></div>`;
  w.style.cssText = 'position:fixed;inset:0;z-index:55;display:grid;place-items:center;background:rgba(10,8,4,.45)';
  w.addEventListener('mousedown', (e) => { if (e.target === w || e.target.id === 'help-close') w.remove(); });
  document.body.appendChild(w);
}
document.addEventListener('keydown', (e) => {
  const typing = /^(input|textarea|select)$/i.test(e.target.tagName);
  if (e.key === '?' && !typing && !e.ctrlKey) { e.preventDefault(); toggleHelp(); }
  else if (e.key === 'Escape' && $('#help-wrap')) $('#help-wrap').remove();
});
