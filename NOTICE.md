# Third-party content and attribution

The MIT license in [LICENSE](LICENSE) covers the **application code** in this repository (`iqra_app/lib/`, `scripts/`).
The Qur'anic text, translations, tafsir and other data below were made by other people and remain under their
own terms. They are included here for reading inside the app, not relicensed.

| Content | Source | Notes |
| --- | --- | --- |
| Arabic Uthmani text, translations, transliteration | [Al Quran Cloud](https://alquran.cloud) (API), which draws on the [Tanzil Project](https://tanzil.net) and other publishers | Each translation is the work of its credited translator (see the translation name in the app). The Arabic text must not be altered. |
| Word-by-word meanings, transliteration, Madani mushaf page and line layout, glyph codes | [Quran.com API](https://quran.com) (Quran Foundation) | The glyph codes (`data/qcf/`) only make sense with the optional fonts and are git-ignored too. |
| Tafsir (Ibn Kathir, Maarif-ul-Quran, Al-Jalalayn, Al-Mukhtasar, Al-Muyassar, As-Sa'di) | [spa5k/tafsir_api](https://github.com/spa5k/tafsir_api), sourced from quran.com | Each tafsir is the work of its author and publisher. |
| Audio | [EveryAyah](https://everyayah.com) | Streamed and cached on the user's computer; no audio is stored in this repository. |
| Old Madina font (the default Qur'an script) | [DigitalKhatt oldmadinafont](https://github.com/DigitalKhatt/oldmadinafont), after the old Madina Mushaf | SIL Open Font License 1.1, see `iqra_app/assets/fonts/OFL-OldMadina.txt`. Always bundled. |
| Scheherazade New font | [SIL International](https://software.sil.org/scheherazade/) | SIL Open Font License 1.1, see `iqra_app/assets/fonts/OFL-ScheherazadeNew.txt`. Always bundled. |
| Madani mushaf fonts (optional) | King Fahd Glorious Qur'an Printing Complex, distributed by [Quran Foundation](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/) | **Not included in this repository.** Kept in git-ignored folders (`iqra_app/assets/fonts/mushaf/`, `iqra_app/assets/qcf/`) and left out of public builds. The terms allow bundling the fonts in an application for the app's own use, require crediting Quran Foundation, and do not allow offering the files separately. Read them before distributing a build that includes these fonts. |
| Reem Kufi (logo lettering) | [The Reem Kufi Project](https://github.com/aliftype/reem-kufi) | SIL Open Font License 1.1, see `assets/OFL-ReemKufi.txt`. Embedded in `assets/logo.svg`. |
| Flutter, media_kit and other packages | [flutter.dev](https://flutter.dev), [pub.dev](https://pub.dev) | BSD / MIT / Apache-2.0, as listed by each package. Bundled in the builds (the app's licence page lists them). |

If you are the author or rights holder of any translation or tafsir included here and would like it removed or
credited differently, please open an issue and it will be taken out promptly.
Which editions are bundled is listed in `scripts/data-config.js`.

## Discover content

| Content | Source | Notes |
| --- | --- | --- |
| Duas and adhkar (Hisn al-Muslim, 132 chapters) | [Islamic-Pro-azkar-API](https://github.com/YousefAsalya/Islamic-Pro-azkar-API) (MIT), from *Hisn al-Muslim* by Sa’id al-Qahtani | Arabic and English text as published in that dataset. |
| Morning and evening adhkar, with transliteration, counts and sources | [Morning-And-Evening-Adhkar-DB](https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB) (MIT) | |
| Arabic text of the Forty Hadith of an-Nawawi | [hadith-api](https://github.com/fawazahmed0/hadith-api) (Unlicense; classical Arabic text) | The chain-of-narrators trailers and reference marks of the source are trimmed for display. The English translation and the explanations are written for IQRA. |
| Classical Arabic text of 168 hadith (Hadith library) | [hadith-api](https://github.com/fawazahmed0/hadith-api) (Unlicense), from the Arabic texts of Bukhari, Muslim, at-Tirmidhi, Abu Dawud and Ibn Majah | Checked against the source at build time. The English translations and explanations are written for IQRA. |
| Prayer times and Qibla | Calculated on the device from the sun’s position (standard twilight-angle methods: Muslim World League, ISNA, Egyptian, Umm al-Qura, Karachi, Gulf, Kuwait, Qatar, Dubai, Singapore, Malaysia/Indonesia, Turkey, Morocco, France). The compass uses the phone’s own magnetic model for the declination. | No data is downloaded or sent; the optional location lookup stays on the device. Times are an aid; check your local mosque for official times, and use the minute adjustments to match it. |
| Adhan recording | Recorded by Aaqib Azeez (Atcovi), from [Wikimedia Commons](https://commons.wikimedia.org) | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The recording is bundled unchanged in `iqra_app/assets/audio/adhan.mp3` and is credited again in the app (Settings). Reuse of this one file follows the same licence. |
| Adhan recording 2 ("Beautiful adhan") | By Adam-synagda, from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain dedication). Bundled unchanged as `iqra_app/assets/audio/adhan_2.ogg`. |
| Adhan recording 3 ("Azan") | By Andrewler, from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Azan.ogg) | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Bundled unchanged as `iqra_app/assets/audio/adhan_3.ogg`; credited again in the app (Settings). |
| Inter (the interface font) | [rsms.me/inter](https://rsms.me/inter/) | SIL Open Font License 1.1, see `iqra_app/assets/fonts/OFL-Inter.txt`. Always bundled. |
| Collections, hadith summaries, in-depth stories (prophets, the Sira, the Companions, women of faith, scholars, history, stories the Prophet ﷺ told), guides, the surah introductions, the 99 Names, calendar occasions, Sunnah fasting days | Written for IQRA (MIT) | The English summaries are not taken from a published translation. Each reported practice names the collection it comes from. This content is for reference and learning; please verify rulings with a qualified scholar. |

## Credits

Credit is given in the app (Settings, then About) and here: the Madani mushaf page layout, the word-by-word meanings and
transliteration come from [Quran.com](https://quran.com) / Quran Foundation. The Arabic text and most translations come from the
[Tanzil Project](https://tanzil.net) via [Al Quran Cloud](https://alquran.cloud). Tafsir comes from
[spa5k/tafsir_api](https://github.com/spa5k/tafsir_api). Audio comes from [EveryAyah](https://everyayah.com).

The page layout is a factual record of where the printed Madani mushaf breaks its lines. If Quran Foundation (or anyone
else) would like any of this data removed or credited differently, open an issue and it will be handled promptly.
