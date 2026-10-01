# Third-party content and attribution

The MIT license in [LICENSE](LICENSE) covers the **application code** in this repository (`src/`, `scripts/`).
The Qur'anic text, translations, tafsir and other data below were made by other people and remain under their
own terms. They are included here for reading inside the app, not relicensed.

| Content | Source | Notes |
| --- | --- | --- |
| Arabic Uthmani text, translations, transliteration | [Al Quran Cloud](https://alquran.cloud) (API), which draws on the [Tanzil Project](https://tanzil.net) and other publishers | Each translation is the work of its credited translator (see the translation name in the app). The Arabic text must not be altered. |
| Word-by-word meanings, transliteration, Madani mushaf page and line layout | [Quran.com API](https://quran.com) (Quran Foundation) | |
| Tafsir (Ibn Kathir, Maarif-ul-Quran, Al-Jalalayn, Al-Mukhtasar, Al-Muyassar, As-Sa'di) | [spa5k/tafsir_api](https://github.com/spa5k/tafsir_api), sourced from quran.com | Each tafsir is the work of its author and publisher. |
| Audio | [EveryAyah](https://everyayah.com) | Streamed and cached on the user's computer; no audio is stored in this repository. |
| Amiri Quran font | [The Amiri Project](https://github.com/aliftype/amiri) | SIL Open Font License 1.1, see `src/fonts/OFL-AmiriQuran.txt`. |
| Electron | [electronjs.org](https://www.electronjs.org) | MIT. Bundled in the Windows builds. |

If you are the author or rights holder of any translation or tafsir included here and would like it removed or
credited differently, please open an issue and it will be taken out promptly.
Which editions are bundled is listed in `scripts/data-config.js`.
