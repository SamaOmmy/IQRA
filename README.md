# Qur'an Reader

A Windows desktop Qur'an reader built with Electron. Everything except audio streaming works offline.

## Download

Grab the installer or the portable .exe from the [latest release](https://github.com/SamaOmmy/Qur-An/releases/latest) (Windows 10/11, 64-bit).
The builds are not code-signed, so Windows SmartScreen may warn you: click **More info**, then **Run anyway**.

## Features

- **Three reading views**
  - *Verses*: each verse with translation(s)
  - *Text*: continuous Arabic text
  - *Pages*: the 604-page Madani mushaf, with the printed line breaks, surah banners and verse markers
- **62 translations** in 40+ languages (plus transliteration), with an optional second translation shown side by side
- **Word-by-word** meanings and transliteration
- **Tafsir** drawer for the current verse: Ibn Kathir, Maarif-ul-Quran, Al-Jalalayn, Al-Mukhtasar (English); Al-Muyassar, As-Sa'di (Arabic)
- Browse by Surah, Juz or mushaf page; search Arabic (diacritics ignored) or the selected translation; jump with `2:255`
- Saved verses; the app reopens where you left off
- **Audio**: 21 reciters, playback speed, continue into the next surah
- **Offline audio**: every verse you listen to is cached automatically; the *Offline* tab downloads whole surahs (or the whole Qur'an) per reciter
- Light / Sepia / Dark themes, adjustable text size

## Run

    npm install
    npm start

## Build a Windows installer

    npm run dist     # NSIS installer + portable .exe in dist/
    npm run pack     # unpacked app folder only (faster, for testing)

## Shortcuts

| Key | Action |
| --- | --- |
| Space | Play / pause |
| N / P | Next / previous verse |
| B | Save current verse |
| T | Open / close tafsir |
| Ctrl+F | Search |
| Ctrl + / Ctrl - | Text size |
| Alt+Left / Alt+Right | Previous / next surah (page in Pages view) |
| Esc | Close popover / tafsir |

Click a verse to select it, double-click to play it.

## Data

The app reads generated files from `data/` (`quran.json`, `translations/`, `words/`, `pages/`, `tafsir/`).
They are built from public sources by two scripts; the raw downloads live in `data/raw/` (git-ignored):

    npm run fetch-data   # downloads: alquran.cloud (text, translations), quran.com API (word-by-word, page layout), spa5k/tafsir_api (tafsir)
    npm run build-data   # compacts them into data/

Which translations and tafsirs are bundled is listed in `scripts/data-config.js`; add one there and re-run both scripts.
Audio comes from everyayah.com and is cached under the app's user-data folder (`Offline` tab -> *Open folder*).

## License

The application code is released under the [MIT License](LICENSE). The Qur'anic text, translations, tafsir and font are
third-party content under their own terms; see [NOTICE.md](NOTICE.md) for sources and attribution.
