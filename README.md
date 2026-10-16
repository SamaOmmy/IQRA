# IQRA

<p align="center"><img src="build/icon.png" width="96" alt="IQRA logo" /></p>

**IQRA** (اقرأ, "Read") is a free, open-source Qur'an app for **Windows PCs and Android phones**, built with Flutter. The Qur'an, the stories, the hadith and the tools all work offline; only audio and extra translations are downloaded the first time you use them.

## Download

Get the latest build from the [releases page](https://github.com/SamaOmmy/IQRA/releases/latest). Pick the file for your device:

| You have | Download | Notes |
| --- | --- | --- |
| **A Windows PC** (Windows 10 or 11) | `IQRA-x.y.z-Windows-Setup.exe` | Installs for your user, no admin rights needed. |
| A Windows PC, without installing | `IQRA-x.y.z-Windows-Portable.zip` | Unzip anywhere and run `iqra.exe`. |
| **An Android phone or tablet** (almost any phone made in the last several years) | `IQRA-x.y.z-Android-arm64.apk` | The smaller file for modern 64-bit phones. |
| An Android phone, and you are not sure | `IQRA-x.y.z-Android-all-phones.apk` | Larger, but runs on every Android phone and tablet. |

On Android, allow "install from this source" when asked. The builds are not code-signed, so Windows SmartScreen may warn you: click **More info**, then **Run anyway**.

## What it does

- **Read**: the 604-page Madani mushaf laid out like the printed book (15 lines per page, surah banners, verse markers), a two-page spread on wide screens, and a verse-by-verse view with translation, word-by-word meanings, transliteration, tafsir and your own notes. Memorisation mode hides the text until you tap it, and a spaced-review schedule brings verses back for you.
- **Listen**: verse-by-verse recitation from 21 reciters, with speed, repeat-each-verse and a sleep timer, and a Now Playing screen that follows along word by word. Verses you hear are kept for offline use, and you can download whole surahs or the whole Qur'an.
- **Discover**: 211 long-form stories (the prophets, tales from the Qur'an, the Sira in order, the Companions, women of faith, scholars, moments in history, teachings in real moments, and the stories the Prophet ﷺ told), a library of 168 hadith and the Forty Hadith of an-Nawawi, each with the Arabic text, an English translation and an explanation; 21 collections of verses and duas, an introduction to every surah, step-by-step guides (wudu, prayer, Friday, fasting, Eid, Umrah, Hajj, the funeral prayer), Hisn al-Muslim, morning and evening adhkar with counters, and the 99 Names.
- **Tools**: prayer times for 240+ cities, your own location, or coordinates you enter, with 14 calculation methods and per-prayer minute adjustments; adhan and reminders on Android; a live qibla compass; tasbih; a Hijri calendar with the dates of the Prophet's life and Muslim history; a salah tracker; a quiz; a zakat calculator; a khatam plan.
- **Library**: bookmarks, notes, memorised verses, reading streak, juz map and milestones.
- **Search** across verses (Arabic with diacritics ignored, or any translation), surahs, stories, hadith and duas.
- 62 translations in 40+ languages and six tafsirs; thirteen colour themes, ten accent colours, a collapsible sidebar on PC, smooth page transitions that you can switch off, backup and restore of your data, and a check for new versions.

## Keyboard shortcuts (Windows)

| Key | Action |
| --- | --- |
| Space | Play / pause |
| ← / → | Turn the mushaf page (the book turns right to left) |
| / | Search |
| Ctrl + B | Collapse or expand the sidebar |
| Media keys | Play / pause, next and previous verse |

## Prayer times and the adhan

Times are calculated on your device from the sun's position, using the method you choose (the app picks the one most used in your country). They are estimates. If your mosque publishes a timetable, open *Prayer times*, then *Adjust minutes*, and match each prayer to it. On Android, turn on *Prayer time reminders* in Settings (and *Play the adhan*) and allow notifications and exact alarms when asked, so the call to prayer sounds at the right minute even when the app is closed. On Windows the reminder appears while the app is running, which can be minimised.

## Build from source

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (with Visual Studio's *Desktop development with C++* workload for Windows, and the Android SDK for Android).

    cd iqra_app
    flutter pub get
    flutter run -d windows

The app bundles generated data from `data/`. Rebuild the bundle with:

    node scripts/prepare-flutter-assets.js

The stories live in `scripts/stories/*.js` and are merged into `iqra_app/assets/data/content.json` with `node scripts/build-content.js`. The hadith library is built from `scripts/hadith-curation*.js`, `scripts/hadith-explain-*.js` and `scripts/nawawi-*.js` with `node scripts/build-discover.js`; every Arabic text is checked against the classical collections when it is built.

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

The application code is released under the [MIT License](LICENSE). The Qur'anic text, translations, tafsir, fonts and the adhan recording are third-party content under their own terms; see [NOTICE.md](NOTICE.md) for sources and attribution.
