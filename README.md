# IQRA

<p align="center"><img src="build/icon.png" width="96" alt="IQRA logo" /></p>

**IQRA** (اقرأ, "Read") is a free, open-source Qur'an app for **Windows and Android**, built with Flutter. The Qur'an, the stories and the tools all work offline; only audio and extra translations are downloaded the first time you use them.

## Download

Get the latest build from the [releases page](https://github.com/SamaOmmy/IQRA/releases/latest):

- **Windows 10/11**: `IQRA-Setup-x.y.z.exe` (installs for your user, no admin needed) or `IQRA-x.y.z-windows-portable.zip`.
- **Android**: `IQRA-x.y.z-arm64-v8a-release.apk` for almost every phone made in the last several years (use `armeabi-v7a` for older 32-bit phones). Allow "install from this source" when asked.

The builds are not code-signed, so Windows SmartScreen may warn you: click **More info**, then **Run anyway**.

## What it does

- **Read**: the 604-page Madani mushaf laid out like the printed book (15 lines per page, surah banners, verse markers), a two-page spread on wide screens, and a verse-by-verse view with translation, word-by-word meanings, tafsir and your own notes. Memorisation mode hides the text until you tap it.
- **Listen**: verse-by-verse recitation from 21 reciters, with speed, repeat-each-verse and a sleep timer, and a Now Playing screen that follows along verse by verse. Verses you hear are kept for offline use.
- **Discover**: 132 in-depth stories (the prophets, Qur'anic tales, the Sira in order, the Companions, women of faith, scholars, moments in history), a library of 100 hadith, 21 collections of verses and duas, an introduction to every surah, step-by-step guides (wudu, prayer, Friday, fasting, Eid, Umrah, Hajj, the funeral prayer), Hisn al-Muslim, morning and evening adhkar with counters, the Forty Hadith and the 99 Names.
- **Tools**: prayer times and qibla (calculated on your device), tasbih, a Hijri calendar with a date converter, a salah tracker, a quiz and a zakat calculator.
- **Library**: bookmarks, notes, memorised verses, reading streak and khatam progress.
- **Search** across verses (Arabic with diacritics ignored, or any translation), surahs, stories, hadith and duas.
- 62 translations in 40+ languages and six tafsirs; nine colour themes, ten accent colours and gentle animations you can switch off.

## Keyboard shortcuts (Windows)

| Key | Action |
| --- | --- |
| Space | Play / pause |
| ← / → | Turn the mushaf page (the book turns right to left) |
| / | Search |
| Media keys | Play / pause, next and previous verse |

## Build from source

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (with Visual Studio's *Desktop development with C++* workload for Windows, and the Android SDK for Android).

    cd iqra_app
    flutter pub get
    flutter run -d windows

The app bundles generated data from `data/`. Rebuild the bundle with:

    node scripts/prepare-flutter-assets.js

### The Madani mushaf script (optional fonts)

Without extra files IQRA draws the mushaf in the open-licensed Old Madina font. For the authentic King Fahd Complex script, the per-page fonts and glyph data are needed; they are **not** in this repository (see [NOTICE.md](NOTICE.md)). Builds you make for yourself can include them; the public release builds do not.

### Release builds

    scripts\build-flutter.ps1            # public build: no licensed fonts
    scripts\build-flutter.ps1 -Local     # personal build with the authentic fonts (never publish it)

The output (Windows installer and portable zip, Android APKs) is written to `iqra_app\dist-public` or `iqra_app\dist-local`.

## Data

`data/` holds the compacted Qur'an text, page layout, word-by-word data, translations, tafsir and Discover data. They are built from public sources by `scripts/fetch-data.js` and `scripts/build-data.js` (raw downloads live in `data/raw/`, git-ignored). The stories, guides, collections and surah introductions are stored in `iqra_app/assets/data/content.json`.

Translations and tafsirs other than the default are downloaded from this repository the first time you pick one, then kept on the device.

## License

The application code is released under the [MIT License](LICENSE). The Qur'anic text, translations, tafsir and fonts are third-party content under their own terms; see [NOTICE.md](NOTICE.md) for sources and attribution.
