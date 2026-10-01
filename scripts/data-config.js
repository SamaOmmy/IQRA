// Which editions get bundled with the app. Identifiers come from api.alquran.cloud (translations)
// and spa5k/tafsir_api (tafsir). Add an entry, re-run fetch-data + build-data, and it shows up in the app.
module.exports = {
  // en.sahih is the built-in default and is stored in quran.json itself.
  translations: [
    // English
    'en.yusufali', 'en.pickthall', 'en.asad', 'en.itani', 'en.hilali', 'en.arberry', 'en.shakir',
    'en.maududi', 'en.qarai', 'en.wahiduddin', 'en.mubarakpuri',
    // South & Central Asia
    'ur.jalandhry', 'ur.maududi', 'ur.qadri', 'ur.kanzuliman', 'hi.hindi', 'bn.bengali', 'ta.tamil',
    'ml.abdulhameed', 'sd.amroti', 'ps.abdulwali', 'ug.saleh', 'uz.sodik', 'tg.ayati', 'dv.divehi',
    // Middle East
    'fa.makarem', 'fa.ayati', 'fa.ghomshei', 'tr.diyanet', 'tr.yazir', 'tr.bulac', 'ku.asan', 'az.musayev',
    // South-East & East Asia
    'id.indonesian', 'id.muntakhab', 'ms.basmeih', 'th.thai', 'zh.jian', 'ja.japanese', 'ko.korean',
    // Europe
    'fr.hamidullah', 'es.cortes', 'de.aburida', 'de.bubenheim', 'it.piccardo', 'nl.keyzer', 'pt.elhayek',
    'ru.kuliev', 'ru.porokhova', 'pl.bielawskiego', 'sv.bernstrom', 'no.berg', 'cs.hrbek', 'ro.grigore',
    'sq.ahmeti', 'bs.korkut', 'bg.theophanov',
    // Africa
    'sw.barwani', 'so.abduh', 'ha.gumi', 'am.sadiq',
  ],
  transliteration: 'en.transliteration',
  tafsirs: [
    { id: 'en-tafisr-ibn-kathir', name: 'Tafsir Ibn Kathir', lang: 'en' },
    { id: 'en-tafsir-maarif-ul-quran', name: 'Maarif-ul-Quran', lang: 'en' },
    { id: 'en-al-jalalayn', name: 'Tafsir al-Jalalayn', lang: 'en' },
    { id: 'en-tafsir-al-mukhtasar', name: 'Al-Mukhtasar', lang: 'en' },
    { id: 'ar-tafsir-muyassar', name: 'التفسير الميسر (Al-Muyassar)', lang: 'ar' },
    { id: 'ar-tafsir-as-saadi', name: 'تفسير السعدي (As-Sa’di)', lang: 'ar' },
  ],
};
