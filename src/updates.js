'use strict';
// Update notices: the bar under the top bar, and the status line in Settings. The work happens in main.js.

const updateBar = $('#update-bar');
let dismissedVersion = null;

function updateLabel(s) {
  switch (s.state) {
    case 'checking': return 'Checking for updates…';
    case 'current': return 'You have the latest version.';
    case 'downloading': return `Downloading IQRA ${s.version}… ${s.percent || 0}%`;
    case 'ready': return `IQRA ${s.version} is ready to install.`;
    case 'available-manual': return `IQRA ${s.version} is available.`;
    case 'dev': return 'Updates are checked in the installed app.';
    case 'error': return 'Could not check for updates. Check your internet connection.';
    default: return '';
  }
}

function showUpdate(s) {
  if (!s) return;
  $('#update-status').textContent = updateLabel(s);
  const action = $('#update-action');
  const show = (s.state === 'ready' || s.state === 'available-manual' || s.state === 'downloading') && s.version !== dismissedVersion;
  updateBar.hidden = !show;
  if (!show) return;
  $('#update-text').textContent = updateLabel(s);
  action.hidden = s.state === 'downloading';
  action.textContent = s.state === 'ready' ? 'Restart now' : 'Download';
  action.dataset.state = s.state;
  updateBar.dataset.version = s.version;
}

$('#update-action').addEventListener('click', (e) => {
  if (e.target.dataset.state === 'ready') window.api.updates.install();
  else window.api.updates.openRelease();
});
$('#update-dismiss').addEventListener('click', () => { dismissedVersion = updateBar.dataset.version; updateBar.hidden = true; });
$('#btn-check-update').addEventListener('click', async () => {
  $('#update-status').textContent = 'Checking…';
  dismissedVersion = null;
  showUpdate(await window.api.updates.check());
});

window.api.updates.onStatus(showUpdate);
window.api.updates.state().then(showUpdate);
window.api.version().then((v) => { $('#app-version').textContent = `v${v}`; });
