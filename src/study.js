'use strict';
// Study panel: translation, word-by-word and tafsir for the current verse.
// data/tafsir/<id>/<surah>.json is an array with one entry per verse: a string, or a number pointing at the earlier
// verse that holds a text shared by a range of verses.

const studyPanel = $('#study');
const studyBody = $('#study-body');

function translationOptionsHtml(withNone, selected) {
  const names = new Intl.DisplayNames(['en'], { type: 'language' });
  const label = (lang) => { try { return names.of(lang) || lang; } catch { return lang; } };
  const groups = new Map();
  for (const t of Q.translations) {
    if (!groups.has(t.lang)) groups.set(t.lang, []);
    groups.get(t.lang).push(t);
  }
  const order = [...groups.keys()].sort((a, b) => (a === 'en' ? -1 : b === 'en' ? 1 : label(a).localeCompare(label(b))));
  return (withNone ? `<option value=""${selected === '' ? ' selected' : ''}>None</option>` : '')
    + order.map((l) => `<optgroup label="${esc(label(l))}">${groups.get(l).map((t) =>
      `<option value="${esc(t.id)}"${t.id === selected ? ' selected' : ''}>${esc(t.name)}</option>`).join('')}</optgroup>`).join('');
}

function setStudyOpen(open) {
  state.studyOpen = open;
  studyPanel.hidden = !open;
  $('#btn-study').classList.toggle('on', open);
  save();
  if (open) renderStudy();
}

function setStudyTab(tab) {
  state.studyTab = tab;
  save();
  $$('[data-study]').forEach((b) => b.classList.toggle('active', b.dataset.study === tab));
  renderStudy();
}

function studyRefresh() {
  if (state.studyOpen) renderStudy();
}

const ARABIC_CHARS = /[؀-ۿ]/g;
function isMostlyArabic(line) {
  const letters = line.replace(/[\s\d\p{P}]/gu, '');
  return letters.length > 0 && (line.match(ARABIC_CHARS) || []).length / letters.length > 0.5;
}

function translationTab(s, a) {
  const blocks = [state.tr1, state.tr2].filter(Boolean).map((id) => `
    <div class="s-block">
      <div class="s-label">${esc(translationMeta(id).name)}</div>
      <p class="s-text" dir="${isRtlTranslation(id) ? 'rtl' : 'ltr'}">${esc(translationText(id, s, a))}</p>
    </div>`).join('');
  const translit = transliterationText(s, a);
  return `
    <div class="s-pickers">
      <select id="study-tr1" class="input" title="Translation">${translationOptionsHtml(false, state.tr1)}</select>
      <select id="study-tr2" class="input" title="Second translation">${translationOptionsHtml(true, state.tr2)}</select>
    </div>
    ${blocks}
    ${translit ? `<div class="s-block"><div class="s-label">Transliteration</div><p class="s-text translit">${esc(translit)}</p></div>` : ''}`;
}

function wordsTab(s, a) {
  const words = wordsOf(s, a);
  if (!words.length) return '<p class="empty">No word data for this verse.</p>';
  return `<div class="s-words" dir="rtl">${words.map(([uth, meaning, translit, qpc]) => `
    <div class="s-word">
      <span class="s-word-ar">${esc(MUSHAF.hafs ? (qpc || uth) : uth)}</span>
      ${translit ? `<span class="s-word-tl">${esc(translit)}</span>` : ''}
      <span class="s-word-tr">${esc(meaning)}</span>
    </div>`).join('')}</div>`;
}

function tafsirTab(s, a) {
  const meta = Q.tafsirs.find((t) => t.id === state.tafsir);
  const rtl = meta.lang === 'ar';
  let entries;
  try { entries = data(`tafsir/${state.tafsir}/${s}.json`); } catch { entries = []; }
  let owner = a;
  let text = entries[a - 1] ?? '';
  if (typeof text === 'number') { owner = text; text = entries[owner - 1]; }

  let note = '';
  if (text) {
    const group = entries.map((e, i) => (i + 1 === owner || e === owner) ? i + 1 : 0).filter(Boolean);
    if (group.length > 1) note = `<div class="s-note">This commentary covers verses ${group[0]}–${group[group.length - 1]} together.</div>`;
  }
  const body = text
    ? text.split('\n').map((l) => l.trim()).filter(Boolean).map((l) =>
        `<p${rtl || isMostlyArabic(l) ? ' class="ar" dir="rtl"' : ''}>${esc(l)}</p>`).join('')
    : '<p class="empty">No commentary for this verse in this edition.</p>';
  return `
    <div class="s-pickers">
      <select id="study-tafsir" class="input" title="Tafsir">${Q.tafsirs.map((t) =>
        `<option value="${esc(t.id)}"${t.id === state.tafsir ? ' selected' : ''}>${esc(t.name)}</option>`).join('')}</select>
    </div>
    ${note}
    <div class="s-tafsir${rtl ? ' rtl' : ''}">${body}</div>`;
}

function renderStudy() {
  const { s, a } = current;
  $('#study-ref').textContent = `${surahOf(s).en} ${s}:${a}`;
  $('#study-sub').textContent = `Juz ${ayahOf(s, a).juz} · Page ${pageOf(s, a)}`;
  $$('[data-study]').forEach((b) => b.classList.toggle('active', b.dataset.study === state.studyTab));
  const head = `<div class="study-ar" dir="rtl">${esc(arabicText(s, a))}</div>`;
  const tab = state.studyTab === 'words' ? wordsTab(s, a) : state.studyTab === 'tafsir' ? tafsirTab(s, a) : translationTab(s, a);
  studyBody.innerHTML = head + tab;
  studyBody.scrollTop = 0;
}

studyBody.addEventListener('change', (e) => {
  if (e.target.id === 'study-tr1') { state.tr1 = e.target.value; save(); onTranslationChanged(); renderStudy(); }
  else if (e.target.id === 'study-tr2') { state.tr2 = e.target.value; save(); onTranslationChanged(); renderStudy(); }
  else if (e.target.id === 'study-tafsir') { state.tafsir = e.target.value; save(); renderStudy(); }
});
$$('[data-study]').forEach((b) => b.addEventListener('click', () => setStudyTab(b.dataset.study)));
$('#study-close').addEventListener('click', () => setStudyOpen(false));
$('#btn-study').addEventListener('click', () => setStudyOpen(!state.studyOpen));
$('#study-prev').addEventListener('click', () => stepVerse(-1));
$('#study-next').addEventListener('click', () => stepVerse(1));
