# IQRA

<p align="center"><img src="assets/logo.svg" width="96" alt="IQRA logo" /></p>

**IQRA** (اقرأ, "Read") is a free, open-source Qur'an reader for Windows, built with Electron. Everything except audio streaming works offline.

## Download

Grab the installer or the portable .exe from the [latest release](https://github.com/SamaOmmy/IQRA/releases/latest) (Windows 10/11, 64-bit).
The builds are not code-signed, so Windows SmartScreen may warn you: click **More info**, then **Run anyway**.

## What it does

- **Mushaf view**: the 604-page Madani mushaf, laid out exactly like the printed book (15 lines per page, surah banners, verse markers). The page fits your window, and two pages show side by side like an open book when there is room. Flip with ← / →, zoom with Ctrl + wheel.
- **Verses view**: verse by verse with translation, transliteration and word-by-word meanings.
- **Study panel** (press `T`): translation, word-by-word and tafsir for the selected verse, beside the page.
- **Jump anywhere** with `Ctrl+K`: a surah name, `2:255`, `page 300`, `juz 20`, or a word to search for.
- 62 translations in 40+ languages, with an optional second translation shown side by side.
- Tafsir: Ibn Kathir, Maarif-ul-Quran, Al-Jalalayn, Al-Mukhtasar, Al-Muyassar, As-Sa'di.
- Audio from 21 reciters with playback speed; every verse you hear is cached, and the Offline panel downloads whole surahs.
- Search the Arabic (diacritics ignored) or the selected translation; saved verses; reopens where you left off.
- Light, Sepia and Dark themes.

## Shortcuts

| Key | Action |
| --- | --- |
| Ctrl+K | Jump to a surah, verse, page or juz |
| ← / → | Next / previous page (the book turns right to left) |
| Space | Play / pause |
| N / P | Next / previous verse |
| B | Save the selected verse |
| T | Open / close the study panel |
| Ctrl+F | Search |
| Ctrl+L | Library (surahs and juz) |
| Ctrl + / Ctrl - / Ctrl+0 | Zoom in / out / reset |
| Esc | Close the open panel |

Click a verse to select it, double-click to play it.

## Run from source

    npm install
    npm start

## The Madani mushaf script (optional fonts)

IQRA always works with the open-licensed Scheherazade New font. For the authentic look of the printed Madani mushaf
(the King Fahd Glorious Qur'an Printing Complex script), download the fonts once:

    npm run fetch-fonts

The fonts are never committed to this repository: their terms allow bundling them inside an application but not
offering them separately. See [NOTICE.md](NOTICE.md) before you publish a build that includes them.

## Build a Windows installer

    npm run dist     # installer + portable .exe in dist/
    npm run pack     # unpacked app folder only (faster, for testing)

## Updates

The installed app checks GitHub Releases in the background, downloads a newer version, and offers a one-click restart
(Settings, then *Check for updates*, also works). The portable build cannot replace itself, so it only tells you when a newer
release exists and links to it.

### Publishing a release (maintainers)

1. Bump `version` in `package.json`.
2. `npm run dist` (run `npm run fetch-fonts` first if the build should include the Madani mushaf script).
3. Create a GitHub release tagged `vX.Y.Z` and upload from `dist/`: `IQRA-Setup-X.Y.Z.exe`, its `.blockmap`, **`latest.yml`**, and `IQRA-X.Y.Z-portable.exe`.
   Installed apps update from `latest.yml`, so it must be attached.

## Data

The app reads generated files from `data/`. They are built from public sources by two scripts; the raw downloads live in `data/raw/` (git-ignored):

    npm run fetch-data   # alquran.cloud (text, translations), quran.com API (words, page layout), spa5k/tafsir_api (tafsir)
    npm run build-data   # compacts them into data/

Which translations and tafsirs are bundled is listed in `scripts/data-config.js`.
Audio comes from everyayah.com and is cached in the app's user-data folder (Offline panel, then *Open folder*).

## License

The application code is released under the [MIT License](LICENSE). The Qur'anic text, translations, tafsir and fonts are
third-party content under their own terms; see [NOTICE.md](NOTICE.md) for sources and attribution.
