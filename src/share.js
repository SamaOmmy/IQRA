'use strict';
// Share a verse or hadith as an image: drawn on a canvas in the Qur'an font, shown in a preview, then copied or saved as PNG.

const SHARE_W = 1080;
const SHARE_H = 1350;
const SHARE_STYLES = {
  emerald: { name: 'Emerald', bg: ['#16967A', '#073B2E'], ink: '#FFF8E4', sub: 'rgba(255,248,228,0.86)', gold: '#E5C06F', star: 'rgba(229,192,111,0.09)' },
  paper: { name: 'Paper', bg: ['#FFFFFF', '#F4EEDD'], ink: '#1B1B19', sub: '#4D4A42', gold: '#A98235', star: 'rgba(169,130,53,0.09)' },
  night: { name: 'Night', bg: ['#16201D', '#070B0A'], ink: '#EDE8D8', sub: 'rgba(237,232,216,0.82)', gold: '#D1AB57', star: 'rgba(209,171,87,0.08)' },
};
let shareState = { data: null, style: 'emerald' };

function starPath(ctx, cx, cy, R) {
  const r = R * 0.7654;
  ctx.beginPath();
  for (let k = 0; k < 16; k++) {
    const a = ((k * 22.5 - 90) * Math.PI) / 180;
    const rad = k % 2 === 0 ? R : r;
    const x = cx + rad * Math.cos(a), y = cy + rad * Math.sin(a);
    if (k === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  }
  ctx.closePath();
}

// Break words into lines no wider than maxW (works for right-to-left too: the canvas measures the run as written).
function wrapLines(ctx, text, maxW) {
  const words = text.split(/\s+/).filter(Boolean);
  const lines = [];
  let line = '';
  for (const w of words) {
    const test = line ? `${line} ${w}` : w;
    if (line && ctx.measureText(test).width > maxW) { lines.push(line); line = w; } else line = test;
  }
  if (line) lines.push(line);
  return lines;
}

// Largest font size (stepping down) at which the text fits in maxH; returns { size, lines }.
function fitText(ctx, text, fontFor, maxW, maxH, lineH, from, to) {
  for (let size = from; size >= to; size -= 2) {
    ctx.font = fontFor(size);
    const lines = wrapLines(ctx, text, maxW);
    if (lines.length * size * lineH <= maxH) return { size, lines };
  }
  ctx.font = fontFor(to);
  const lines = wrapLines(ctx, text, maxW);
  const maxLines = Math.max(1, Math.floor(maxH / (to * lineH)));
  if (lines.length > maxLines) { lines.length = maxLines; lines[maxLines - 1] = lines[maxLines - 1].replace(/\s*\S*$/, '') + '…'; }
  return { size: to, lines };
}

function drawShareCard(canvas, { ar, tr, ref }, styleId) {
  const S = SHARE_STYLES[styleId] || SHARE_STYLES.emerald;
  canvas.width = SHARE_W;
  canvas.height = SHARE_H;
  const ctx = canvas.getContext('2d');
  const g = ctx.createLinearGradient(0, 0, SHARE_W * 0.4, SHARE_H);
  g.addColorStop(0, S.bg[0]);
  g.addColorStop(1, S.bg[1]);
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, SHARE_W, SHARE_H);

  ctx.fillStyle = S.star; // large star watermark
  starPath(ctx, SHARE_W / 2, SHARE_H * 0.46, 450);
  ctx.fill();
  ctx.strokeStyle = S.gold;
  ctx.globalAlpha = 0.7;
  ctx.lineWidth = 3;
  ctx.strokeRect(46, 46, SHARE_W - 92, SHARE_H - 92);
  ctx.globalAlpha = 0.35;
  ctx.lineWidth = 1.5;
  ctx.strokeRect(62, 62, SHARE_W - 124, SHARE_H - 124);
  ctx.globalAlpha = 1;

  ctx.fillStyle = S.gold;
  starPath(ctx, SHARE_W / 2, 128, 26);
  ctx.fill();

  const left = 110, width = SHARE_W - 220;
  const hasTr = Boolean(tr);
  const arBox = { top: 190, height: hasTr ? 560 : 800 };
  ctx.textBaseline = 'alphabetic';
  ctx.direction = 'rtl';
  ctx.textAlign = 'center';
  const arFit = fitText(ctx, ar, (s) => `${s}px "Old Madina", "Scheherazade New", serif`, width, arBox.height, 1.85, hasTr ? 66 : 76, 26);
  ctx.fillStyle = S.ink;
  ctx.font = `${arFit.size}px "Old Madina", "Scheherazade New", serif`;
  const arH = arFit.lines.length * arFit.size * 1.85;
  let y = arBox.top + (arBox.height - arH) / 2 + arFit.size * 1.3;
  if (!hasTr) y += 20;
  for (const line of arFit.lines) { ctx.fillText(line, SHARE_W / 2, y); y += arFit.size * 1.85; }

  let bottom = arBox.top + arBox.height;
  if (hasTr) {
    ctx.direction = 'ltr';
    ctx.strokeStyle = S.gold;
    ctx.globalAlpha = 0.6;
    ctx.beginPath();
    ctx.moveTo(SHARE_W / 2 - 60, bottom + 12);
    ctx.lineTo(SHARE_W / 2 + 60, bottom + 12);
    ctx.stroke();
    ctx.globalAlpha = 1;
    const trFit = fitText(ctx, tr, (s) => `${s}px "Segoe UI", system-ui, sans-serif`, width, 300, 1.45, 34, 22);
    ctx.fillStyle = S.sub;
    ctx.font = `${trFit.size}px "Segoe UI", system-ui, sans-serif`;
    let ty = bottom + 70;
    for (const line of trFit.lines) { ctx.fillText(line, SHARE_W / 2, ty); ty += trFit.size * 1.45; }
  }

  ctx.direction = 'ltr';
  ctx.fillStyle = S.gold;
  ctx.font = '600 30px "Segoe UI", system-ui, sans-serif';
  ctx.fillText(ref, SHARE_W / 2, SHARE_H - 150);
  ctx.fillStyle = S.sub;
  ctx.font = '500 24px "Segoe UI", system-ui, sans-serif';
  ctx.fillText('IQRA · Qur’an reader', SHARE_W / 2, SHARE_H - 100);
}

const shareWrap = $('#share-wrap');
const shareCanvas = $('#share-canvas');

async function openShare(data) {
  shareState = { data, style: shareState.style || 'emerald' };
  await fontsReady;
  await document.fonts.load('40px "Old Madina"', data.ar.slice(0, 20));
  shareWrap.hidden = false;
  renderShare();
}

function renderShare() {
  drawShareCard(shareCanvas, shareState.data, shareState.style);
  $$('#share-styles [data-style]').forEach((b) => b.classList.toggle('active', b.dataset.style === shareState.style));
}

const shareBlob = () => new Promise((resolve) => shareCanvas.toBlob(resolve, 'image/png'));
$('#share-styles').addEventListener('click', (e) => {
  const b = e.target.closest('[data-style]');
  if (b) { shareState.style = b.dataset.style; renderShare(); }
});
$('#share-copy').addEventListener('click', async () => {
  try { await navigator.clipboard.write([new ClipboardItem({ 'image/png': await shareBlob() })]); toast('Image copied. Paste it anywhere.'); } catch { toast('Could not copy the image. Use Save instead.'); }
});
$('#share-save').addEventListener('click', async () => {
  const url = URL.createObjectURL(await shareBlob());
  const a = document.createElement('a');
  a.href = url;
  a.download = `IQRA-${shareState.data.ref.replace(/[^\w]+/g, '-').replace(/^-|-$/g, '')}.png`;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
  toast('Saving image…');
});
$('#share-text').addEventListener('click', () => copyText(`${shareState.data.ar}\n\n${shareState.data.tr || ''}\n— ${shareState.data.ref}`.replace(/\n\n\n/, '\n\n'), 'Text copied'));
$('#share-close').addEventListener('click', () => { shareWrap.hidden = true; });
shareWrap.addEventListener('mousedown', (e) => { if (e.target === shareWrap) shareWrap.hidden = true; });

// A verse (or range) from the Qur'an as share data.
function verseShareData(s, a, b = a) {
  const ar = Array.from({ length: b - a + 1 }, (_, i) => arabicText(s, a + i)).join(' ');
  const tr = Array.from({ length: b - a + 1 }, (_, i) => translationText(state.tr1, s, a + i)).join(' ');
  return { ar, tr, ref: `${surahOf(s).en} ${s}:${a}${b > a ? `–${b}` : ''}` };
}
