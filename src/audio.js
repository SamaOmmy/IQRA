'use strict';
// Verse-by-verse playback (qaudio:// is served by the main process from the offline cache, downloading on demand)
// and the "Offline" sidebar panel that manages downloaded recitations.

const audio = new Audio();
let playing = null; // { s, a } while a verse is loaded

const audioUrl = (s, a, reciter = state.reciter) => `qaudio://a/${reciter}/${pad3(s)}${pad3(a)}.mp3`;
const reciterName = (id) => RECITERS.find(([rid]) => rid === id)?.[1] ?? id;

function adjacentVerse(s, a, dir) {
  if (dir > 0) {
    if (a < surahOf(s).ayahs.length) return { s, a: a + 1 };
    return s < 114 ? { s: s + 1, a: 1 } : null;
  }
  if (a > 1) return { s, a: a - 1 };
  return s > 1 ? { s: s - 1, a: surahOf(s - 1).ayahs.length } : null;
}

function nextVerse(s, a) {
  const next = adjacentVerse(s, a, 1);
  return next && (next.s === s || state.continuous) ? next : null;
}

function setNowPlayingLabel() {
  const ref = playing || current;
  $('#now-playing').textContent = playing
    ? `${surahOf(ref.s).en} · verse ${ref.a} · ${reciterName(state.reciter)}`
    : `Ready: ${surahOf(ref.s).en} · verse ${ref.a}`;
  $('#p-play').textContent = audio.paused ? '▶' : '⏸';
}

function playVerse(s, a) {
  playing = { s, a };
  showVerse(s, a, { scroll: true });
  audio.src = audioUrl(s, a);
  audio.playbackRate = state.speed;
  audio.play().catch(() => {}); // failures are surfaced by the 'error' handler
  setNowPlayingLabel();
  const next = nextVerse(s, a);
  if (next) { // asking for the next verse makes the main process cache it, so it starts instantly
    const pre = new Audio();
    pre.preload = 'auto';
    pre.src = audioUrl(next.s, next.a);
  }
}

function togglePlay() {
  if (!playing) { playVerse(current.s, current.a); return; }
  if (audio.paused) audio.play().catch(() => {}); else audio.pause();
}

function skip(dir) {
  const from = playing || current;
  const to = adjacentVerse(from.s, from.a, dir);
  if (to) playVerse(to.s, to.a);
}

audio.addEventListener('play', setNowPlayingLabel);
audio.addEventListener('pause', setNowPlayingLabel);
audio.addEventListener('ended', () => {
  const next = nextVerse(playing.s, playing.a);
  if (next) playVerse(next.s, next.a);
  else { playing = null; setNowPlayingLabel(); }
});
audio.addEventListener('error', () => {
  toast('Could not load audio. Check your internet connection, or download this surah in the Offline tab.');
  $('#p-play').textContent = '▶';
});

$('#p-play').addEventListener('click', togglePlay);
$('#p-next').addEventListener('click', () => skip(1));
$('#p-prev').addEventListener('click', () => skip(-1));
$('#p-continuous').addEventListener('change', (e) => { state.continuous = e.target.checked; save(); });
$('#speed').addEventListener('change', (e) => { state.speed = +e.target.value; audio.playbackRate = state.speed; save(); });
$('#reciter').innerHTML = RECITERS.map(([id, name]) => `<option value="${esc(id)}">${esc(name)}</option>`).join('');
$('#reciter').addEventListener('change', (e) => {
  state.reciter = e.target.value;
  save();
  if (playing) {
    const wasPaused = audio.paused;
    playVerse(playing.s, playing.a);
    if (wasPaused) audio.pause();
  }
  if ($('#panel-offline').classList.contains('active')) refreshOffline();
});

// ---------- Offline panel ----------
let offlineHave = new Array(114).fill(0);
let downloading = false;
let lastRefresh = 0;

async function refreshOffline() {
  const [have, usage] = await Promise.all([window.api.audio.status(state.reciter), window.api.audio.usage(state.reciter)]);
  offlineHave = have.length ? have : new Array(114).fill(0);
  $('#offline-title').textContent = reciterName(state.reciter);
  $('#offline-usage').textContent = usage.files
    ? `${usage.files.toLocaleString()} verses saved · ${(usage.bytes / 1048576).toFixed(0)} MB`
    : 'Nothing saved yet';
  renderOfflineList();
  updateOfflineButtons();
}

function renderOfflineList() {
  $('#offline-list').innerHTML = S.map((s) => {
    const have = offlineHave[s.n - 1], total = s.ayahs.length, complete = have >= total;
    return `<li data-off="${s.n}">
      <div class="num"><span>${s.n}</span></div>
      <div class="names">
        <div class="name">${esc(s.en)}</div>
        <div class="sub">${complete ? '✓ Downloaded' : have ? `${have} / ${total} verses` : `${total} verses`}</div>
      </div>
      ${complete
        ? '<button class="btn mini" data-off-act="remove" title="Delete from this computer">Delete</button>'
        : `<button class="btn mini" data-off-act="download">${have ? 'Resume' : 'Download'}</button>`}
    </li>`;
  }).join('');
}

function updateOfflineButtons() {
  $('#off-cancel').hidden = !downloading;
  $('#off-all').hidden = downloading;
  $('#off-clear').hidden = downloading;
  $('#off-progress').hidden = !downloading;
  $$('#offline-list [data-off-act]').forEach((b) => { b.disabled = downloading; });
}

async function startDownload(surahs) {
  if (downloading) return;
  downloading = true;
  updateOfflineButtons();
  const reply = await window.api.audio.download(state.reciter, surahs);
  if (reply.error) toast(reply.error);
  downloading = false;
  await refreshOffline();
}

window.api.audio.onProgress((p) => {
  if (!p.running) {
    if (p.cancelled) toast('Download cancelled');
    else if (p.failed) toast(`Stopped: ${p.failed} verses could not be downloaded. Check your connection and press Resume.`);
    else toast('Download complete');
    return;
  }
  if (p.reciter !== state.reciter) return;
  const pct = p.total ? Math.round((p.done / p.total) * 100) : 0;
  $('#off-progress .bar').style.width = `${pct}%`;
  $('#off-progress span').textContent = `${p.done.toLocaleString()} / ${p.total.toLocaleString()} verses (${pct}%)${p.surah ? ` · ${surahOf(p.surah).en}` : ''}`;
  if (Date.now() - lastRefresh > 1500) { lastRefresh = Date.now(); refreshOffline(); }
});

$('#offline-list').addEventListener('click', async (e) => {
  const btn = e.target.closest('[data-off-act]');
  if (!btn) return;
  const n = +btn.closest('li').dataset.off;
  if (btn.dataset.offAct === 'download') startDownload([n]);
  else {
    const reply = await window.api.audio.remove(state.reciter, n);
    if (reply.error) toast(reply.error);
    refreshOffline();
  }
});
$('#off-all').addEventListener('click', () => {
  if (confirm(`Download the whole Qur'an for ${reciterName(state.reciter)}?\n\nThis is a large download (typically several hundred MB). You can cancel and resume at any time.`)) {
    startDownload(S.map((s) => s.n));
  }
});
$('#off-cancel').addEventListener('click', () => window.api.audio.cancel());
$('#off-clear').addEventListener('click', async () => {
  if (!confirm(`Delete all downloaded audio for ${reciterName(state.reciter)}?`)) return;
  const reply = await window.api.audio.remove(state.reciter, null);
  if (reply.error) toast(reply.error);
  refreshOffline();
});
$('#off-folder').addEventListener('click', () => window.api.audio.openFolder());
