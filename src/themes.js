'use strict';
// Colour themes, accent colours and the motion switch. The colours themselves live in polish.css.

const THEME_LIST = [
  { id: 'auto', name: 'Auto', desk: '#e7e6e2', paper: '#ffffff', ink: '#1b1b19', accent: '#0e6b53', half: '#0a0e0d' },
  { id: 'light', name: 'Light', desk: '#e7e6e2', paper: '#ffffff', ink: '#1b1b19', accent: '#0e6b53' },
  { id: 'sepia', name: 'Sepia', desk: '#d8c9a4', paper: '#f4e8ca', ink: '#3e3220', accent: '#7c4f16' },
  { id: 'rose', name: 'Rose', desk: '#efe2df', paper: '#fffaf8', ink: '#2e1d20', accent: '#a82d4c' },
  { id: 'ocean', name: 'Ocean', desk: '#dde7ee', paper: '#fbfdff', ink: '#13202a', accent: '#0d6aa6' },
  { id: 'lavender', name: 'Lavender', desk: '#e6e3f0', paper: '#fdfcff', ink: '#1f1b2e', accent: '#5b43b5' },
  { id: 'dark', name: 'Dark', desk: '#0a0e0d', paper: '#151b19', ink: '#e8e3d3', accent: '#4cc3a0' },
  { id: 'midnight', name: 'Midnight', desk: '#0a0f1e', paper: '#151f3b', ink: '#e7eaf7', accent: '#82a8ff' },
  { id: 'forest', name: 'Forest', desk: '#0c1a13', paper: '#162f20', ink: '#e6eddb', accent: '#a3d977' },
  { id: 'amoled', name: 'Black', desk: '#000000', paper: '#0c0c0c', ink: '#efebe0', accent: '#5fd6ac' },
];
const ACCENTS = [
  ['', 'Theme colour'], ['#0f8a6a', 'Emerald'], ['#0d8f9a', 'Teal'], ['#2f6fd6', 'Blue'], ['#6a5bd6', 'Indigo'],
  ['#8a4fd0', 'Violet'], ['#cc3d6a', 'Rose'], ['#d0572d', 'Terracotta'], ['#a9650f', 'Amber'], ['#5d6b7a', 'Slate'],
];

const colorScheme = window.matchMedia('(prefers-color-scheme: dark)');
const resolveTheme = () => (state.theme === 'auto' ? (colorScheme.matches ? 'dark' : 'light') : state.theme);

function inkFor(hex) {
  const n = parseInt(hex.slice(1), 16);
  const lum = (0.2126 * (n >> 16) + 0.7152 * ((n >> 8) & 255) + 0.0722 * (n & 255)) / 255;
  return lum > 0.62 ? '#10150f' : '#ffffff';
}

function applyTheme() {
  if (!THEME_LIST.some((t) => t.id === state.theme)) state.theme = 'light';
  const root = document.documentElement;
  root.dataset.theme = resolveTheme();
  const st = root.style;
  if (state.accent) {
    st.setProperty('--accent', state.accent);
    st.setProperty('--accent-ink', inkFor(state.accent));
    st.setProperty('--hero-a', `color-mix(in srgb, ${state.accent} 76%, #000)`);
    st.setProperty('--hero-b', `color-mix(in srgb, ${state.accent} 46%, #000)`);
    st.setProperty('--hero-c', `color-mix(in srgb, ${state.accent} 24%, #000)`);
  } else {
    ['--accent', '--accent-ink', '--hero-a', '--hero-b', '--hero-c'].forEach((p) => st.removeProperty(p));
  }
  root.classList.toggle('no-motion', state.motion === false);
  $$('#theme-grid .theme-opt').forEach((b) => b.classList.toggle('active', b.dataset.theme === state.theme));
  $$('#accent-row .accent-dot').forEach((b) => b.classList.toggle('active', (b.dataset.accent || '') === (state.accent || '')));
  const m = $('#chk-motion');
  if (m) m.checked = state.motion !== false;
}
colorScheme.addEventListener('change', () => { if (state.theme === 'auto') applyTheme(); });

function buildThemePicker() {
  $('#theme-grid').innerHTML = THEME_LIST.map((t) => `<button class="theme-opt" data-theme="${t.id}" title="${t.name}">
    <span class="theme-sw" style="background:${t.half ? `linear-gradient(115deg, ${t.desk} 50%, ${t.half} 50%)` : t.desk}">
      <i class="pg" style="background:${t.paper}"></i>
      <i class="ln" style="background:${t.ink};top:34%;opacity:.55"></i><i class="ln" style="background:${t.ink};top:50%;opacity:.4"></i><i class="ln" style="background:${t.ink};top:66%;opacity:.3"></i>
      <i class="dot" style="background:${t.accent}"></i>
    </span>${t.name}</button>`).join('');
  $('#accent-row').innerHTML = ACCENTS.map(([c, n]) => `<button class="accent-dot${c ? '' : ' auto'}" data-accent="${c}" title="${n}" aria-label="${n}"${c ? ` style="background:${c}"` : ''}></button>`).join('');
}

function fadeThemeChange(fn) {
  const root = document.documentElement;
  root.classList.add('theme-fade');
  fn();
  save();
  applyTheme();
  setTimeout(() => root.classList.remove('theme-fade'), 450);
}

buildThemePicker();
$('#theme-grid').addEventListener('click', (e) => { const b = e.target.closest('[data-theme]'); if (b) fadeThemeChange(() => { state.theme = b.dataset.theme; }); });
$('#accent-row').addEventListener('click', (e) => { const b = e.target.closest('[data-accent]'); if (b) fadeThemeChange(() => { state.accent = b.dataset.accent; }); });
$('#chk-motion').addEventListener('change', (e) => { state.motion = e.target.checked; save(); applyTheme(); });
