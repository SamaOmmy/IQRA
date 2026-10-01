# Third-party content and attribution

The MIT license in [LICENSE](LICENSE) covers the **application code** in this repository (`src/`, `scripts/`).
The Qur'anic text, translations, tafsir and other data below were made by other people and remain under their
own terms. They are included here for reading inside the app, not relicensed.

| Content | Source | Notes |
| --- | --- | --- |
| Arabic Uthmani text, translations, transliteration | [Al Quran Cloud](https://alquran.cloud) (API), which draws on the [Tanzil Project](https://tanzil.net) and other publishers | Each translation is the work of its credited translator (see the translation name in the app). The Arabic text must not be altered. |
| Word-by-word meanings, transliteration, Madani mushaf page and line layout, glyph codes | [Quran.com API](https://quran.com) (Quran Foundation) | The glyph codes (`data/qcf/`) only make sense with the optional fonts and are git-ignored too. |
| Tafsir (Ibn Kathir, Maarif-ul-Quran, Al-Jalalayn, Al-Mukhtasar, Al-Muyassar, As-Sa'di) | [spa5k/tafsir_api](https://github.com/spa5k/tafsir_api), sourced from quran.com | Each tafsir is the work of its author and publisher. |
| Audio | [EveryAyah](https://everyayah.com) | Streamed and cached on the user's computer; no audio is stored in this repository. |
| Scheherazade New font | [SIL International](https://software.sil.org/scheherazade/) | SIL Open Font License 1.1, see `src/fonts/OFL-ScheherazadeNew.txt`. Always bundled. |
| Madani mushaf fonts (optional) | King Fahd Glorious Qur'an Printing Complex, distributed by [Quran Foundation](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/) | **Not included in this repository.** Fetched by `npm run fetch-fonts` into a git-ignored folder. The terms allow bundling the fonts in an application for the app's own use, require crediting Quran Foundation, and do not allow offering the files separately. Read them before distributing a build that includes these fonts. |
| Reem Kufi (logo lettering) | [The Reem Kufi Project](https://github.com/aliftype/reem-kufi) | SIL Open Font License 1.1, see `assets/OFL-ReemKufi.txt`. Embedded in `assets/logo.svg`. |
| Electron | [electronjs.org](https://www.electronjs.org) | MIT. Bundled in the Windows builds. |

If you are the author or rights holder of any translation or tafsir included here and would like it removed or
credited differently, please open an issue and it will be taken out promptly.
Which editions are bundled is listed in `scripts/data-config.js`.

## Discover content

| Content | Source | Notes |
| --- | --- | --- |
| Duas and adhkar (Hisn al-Muslim, 132 chapters) | [Islamic-Pro-azkar-API](https://github.com/YousefAsalya/Islamic-Pro-azkar-API) (MIT), from *Hisn al-Muslim* by Sa’id al-Qahtani | Arabic and English text as published in that dataset. |
| Morning and evening adhkar, with transliteration, counts and sources | [Morning-And-Evening-Adhkar-DB](https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB) (MIT) | |
| Arabic text of the Forty Hadith of an-Nawawi | [hadith-api](https://github.com/fawazahmed0/hadith-api) (Unlicense; classical Arabic text) | |
| Collections, hadith summaries, the 99 Names, calendar occasions, Sunnah fasting days | Written for IQRA (MIT) | The English summaries are not taken from a published translation. Each reported practice names the collection it comes from. This content is for reference and learning; please verify rulings with a qualified scholar. |

## Credits

Credit is given in the app (Settings, then About) and here: the Madani mushaf page layout, the word-by-word meanings and
transliteration come from [Quran.com](https://quran.com) / Quran Foundation. The Arabic text and most translations come from the
[Tanzil Project](https://tanzil.net) via [Al Quran Cloud](https://alquran.cloud). Tafsir comes from
[spa5k/tafsir_api](https://github.com/spa5k/tafsir_api). Audio comes from [EveryAyah](https://everyayah.com).

The page layout is a factual record of where the printed Madani mushaf breaks its lines. If Quran Foundation (or anyone
else) would like any of this data removed or credited differently, open an issue and it will be handled promptly.
