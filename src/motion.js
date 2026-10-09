'use strict';
// Motion: scroll reveals, count-up numbers, sparkles, the equaliser, and a reading bar on story pages.
// Every effect checks `motionOn()`, so the Animations switch in Settings and the system's reduced-motion setting turn them all off.

const motionOn = () => state.motion !== false && !reducedMotion();

// ---------- Scroll reveal ----------
let revealer = null;
function setupReveal() {
  if (revealer) revealer.disconnect();
  revealer = null;
  if (!motionOn() || !('IntersectionObserver' in window)) return;
  revealer = new IntersectionObserver((entries) => {
    for (const en of entries) if (en.isIntersecting) { en.target.classList.add('in'); revealer.unobserve(en.target); }
  }, { root: reader, rootMargin: '0px 0px -6% 0px', threshold: 0.05 });
  const targets = $$('.deep > *, .story > p, .lessons, .facts, .hadith, .d-sec, .d-hadith, .d-fast, .guide-steps > li, .cal-day, .tas-preset', reader);
  targets.forEach((el, i) => { el.classList.add('rv'); revealer.observe(el); });
}

// ---------- Count-up numbers ----------
function countUp() {
  if (!motionOn()) return;
  $$('.stat .big, .quiz-score', reader).forEach((el) => {
    const m = /^(\d+)(%?)$/.exec(el.textContent.trim());
    if (!m) return;
    const end = +m[1], suffix = m[2], t0 = performance.now(), dur = 900;
    const tick = (t) => {
      const k = Math.min(1, (t - t0) / dur);
      el.textContent = Math.round(end * (1 - Math.pow(1 - k, 3))) + suffix;
      if (k < 1 && el.isConnected) requestAnimationFrame(tick);
    };
    el.textContent = '0' + suffix;
    requestAnimationFrame(tick);
  });
  $$('.pc', reader).forEach((el, i) => el.style.setProperty('--i', Math.min(i, 400)));
}

// ---------- Sparkles ----------
function sparkle(el, glyph = '✦', n = 6) {
  if (!motionOn()) return;
  const r = el.getBoundingClientRect();
  for (let i = 0; i < n; i++) {
    const s = document.createElement('span');
    s.className = 'spark';
    s.textContent = glyph;
    s.style.left = `${r.left + r.width * (0.15 + 0.7 * Math.random())}px`;
    s.style.top = `${r.top + r.height * 0.3}px`;
    s.style.animationDelay = `${i * 60}ms`;
    s.style.fontSize = `${14 + Math.random() * 14}px`;
    document.body.appendChild(s);
    setTimeout(() => s.remove(), 1200 + i * 60);
  }
}
function pop(el) { el.classList.remove('pop'); void el.offsetWidth; el.classList.add('pop'); }

// ---------- Reading bar on story pages ----------
function updateReadBar() {
  if (state.view !== 'discover' || !['story', 'guide'].includes(discoverRoute.page)) return;
  const max = reader.scrollHeight - reader.clientHeight;
  $('#progress i').style.width = `${max > 0 ? Math.min(100, (reader.scrollTop / max) * 100) : 0}%`;
}
reader.addEventListener('scroll', updateReadBar, { passive: true });

// ---------- Hooks ----------
const renderDiscoverBase = renderDiscover;
renderDiscover = function renderDiscoverWithMotion() {
  renderDiscoverBase();
  setupReveal();
  countUp();
  if (['story', 'guide'].includes(discoverRoute.page)) updateReadBar();
  else $('#progress i').style.width = '0%';
};

// the equaliser and pulse follow the audio
for (const ev of ['play', 'playing', 'pause', 'ended', 'emptied']) {
  audio.addEventListener(ev, () => document.body.classList.toggle('playing', !audio.paused && !audio.ended));
}
