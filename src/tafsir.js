'use strict';
// Tafsir drawer: commentary for the current verse. data/tafsir/<id>/<surah>.json is an array with one entry per verse:
// a string, or a number pointing at the earlier verse that holds a text shared by a range of verses.

const tafsirPanel = $('#tafsir');

function setTafsirOpen(open) {
  state.tafsirOpen = open;
  tafsirPanel.hidden = !open;
  $('#tafsir-toggle').classList.toggle('on', open);
  save();
  if (open) renderTafsir();
  if (state.view === 'pages') requestAnimationFrame(fitPage); // the reading area just changed width
}

function tafsirRefresh() {
  if (state.tafsirOpen) renderTafsir();
}

const ARABIC_CHARS = /[؀-ۿ]/g;
function isMostlyArabic(line) {
  const letters = line.replace(/[\s\d\p{P}]/gu, '');
  return letters.length > 0 && (line.match(ARABIC_CHARS) || []).length / letters.length > 0.5;
}

function renderTafsir() {
  const { s, a } = current;
  const meta = Q.tafsirs.find((t) => t.id === state.tafsir);
  const rtl = meta.lang === 'ar';
  $('#tafsir-ref').textContent = `${surahOf(s).en} ${s}:${a}`;

  let entries;
  try { entries = data(`tafsir/${state.tafsir}/${s}.json`); } catch { entries = []; }
  let owner = a;
  let text = entries[a - 1] ?? '';
  if (typeof text === 'number') { owner = text; text = entries[owner - 1]; }

  // Verses sharing this commentary, e.g. "verses 3–5".
  let note = '';
  if (text) {
    const group = entries.map((e, i) => (i + 1 === owner || e === owner) ? i + 1 : 0).filter(Boolean);
    if (group.length > 1) note = `<div class="tafsir-note">This commentary covers verses ${group[0]}–${group[group.length - 1]} together.</div>`;
  }

  const verse = ayahOf(s, a);
  const body = text
    ? text.split('\n').map((l) => l.trim()).filter(Boolean).map((l) =>
        `<p${rtl || isMostlyArabic(l) ? ' class="ar" dir="rtl"' : ''}>${esc(l)}</p>`).join('')
    : '<p class="empty">No commentary for this verse in this edition.</p>';

  $('#tafsir-body').innerHTML = `
    <div class="tafsir-verse arabic" dir="rtl">${esc(verse.a)}</div>
    ${note}
    <div class="tafsir-text${rtl ? ' rtl' : ''}">${body}</div>`;
  $('#tafsir-body').scrollTop = 0;
}

$('#tafsir-select').innerHTML = Q.tafsirs.map((t) => `<option value="${esc(t.id)}">${esc(t.name)}</option>`).join('');
$('#tafsir-select').value = state.tafsir;
$('#tafsir-select').addEventListener('change', (e) => { state.tafsir = e.target.value; save(); renderTafsir(); });
$('#tafsir-close').addEventListener('click', () => setTafsirOpen(false));
$('#tafsir-toggle').addEventListener('click', () => setTafsirOpen(!state.tafsirOpen));
$('#tafsir-prev').addEventListener('click', () => stepVerse(-1));
$('#tafsir-next').addEventListener('click', () => stepVerse(1));
