// Renders assets/logo.svg into the icon files the app and installer use. Run with Electron:
//   npx electron scripts/make-icons.js
// Writes build/icon.ico (16-256px), build/icon.png (512px) and src/assets/logo-*.png.
const { app, BrowserWindow } = require('electron');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const ICO_SIZES = [16, 24, 32, 48, 64, 128, 256];
const PNG_SIZES = [...ICO_SIZES, 512];

function buildIco(images) {
  const header = Buffer.alloc(6 + 16 * images.length);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = header.length;
  images.forEach(({ size, png }, i) => {
    const e = 6 + i * 16;
    header.writeUInt8(size >= 256 ? 0 : size, e);
    header.writeUInt8(size >= 256 ? 0 : size, e + 1);
    header.writeUInt16LE(1, e + 4);   // colour planes
    header.writeUInt16LE(32, e + 6);  // bits per pixel
    header.writeUInt32LE(png.length, e + 8);
    header.writeUInt32LE(offset, e + 12);
    offset += png.length;
  });
  return Buffer.concat([header, ...images.map((i) => i.png)]);
}

app.whenReady().then(async () => {
  const win = new BrowserWindow({ show: false });
  await win.loadURL('data:text/html,<meta charset=utf-8><body>');
  const svg = fs.readFileSync(path.join(root, 'assets', 'logo.svg'), 'utf8');
  const rendered = await win.webContents.executeJavaScript(`(async () => {
    const img = new Image();
    img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(${JSON.stringify(svg)});
    await img.decode();
    await document.fonts.ready;
    const out = {};
    for (const s of ${JSON.stringify(PNG_SIZES)}) {
      const c = document.createElement('canvas');
      c.width = c.height = s;
      const g = c.getContext('2d');
      g.imageSmoothingQuality = 'high';
      g.drawImage(img, 0, 0, s, s);
      out[s] = c.toDataURL('image/png').split(',')[1];
    }
    return out;
  })()`);

  fs.mkdirSync(path.join(root, 'build'), { recursive: true });
  fs.mkdirSync(path.join(root, 'src', 'assets'), { recursive: true });
  const png = (s) => Buffer.from(rendered[s], 'base64');
  fs.writeFileSync(path.join(root, 'build', 'icon.ico'), buildIco(ICO_SIZES.map((size) => ({ size, png: png(size) }))));
  fs.writeFileSync(path.join(root, 'build', 'icon.png'), png(512));
  fs.writeFileSync(path.join(root, 'src', 'assets', 'logo-512.png'), png(512));
  fs.writeFileSync(path.join(root, 'src', 'assets', 'logo-96.png'), png(128));
  console.log('icons written');
  app.exit(0);
});
