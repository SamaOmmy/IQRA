'use strict';
// Authored content for the Discover tab. The large texts (Hisn al-Muslim, morning/evening adhkar, the Arabic of the Forty
// Hadith) live in data/discover/*.json; this file holds the curation around them: collections, occasions, summaries.
//
// Verse references are [surah, firstAyah, lastAyah?]; their Arabic and translation come from the bundled Qur'an data.
// Hisn al-Muslim chapters are referenced by their index in data/discover/hisn.json.
// Every claim about the Sunnah names the collection it is reported in.

const DISCOVER = {};

// ---------- Verse of the day (rotates by date) ----------
DISCOVER.dailyVerses = [
  [2, 152], [2, 153], [2, 186], [2, 255], [2, 286], [3, 139], [3, 159], [3, 173], [5, 8], [6, 162, 163],
  [9, 51], [10, 62, 63], [12, 87], [13, 28], [14, 7], [16, 97], [17, 9], [18, 46], [20, 46], [20, 114],
  [25, 63], [29, 45], [31, 17], [33, 41, 42], [39, 53], [40, 60], [49, 10], [49, 13], [51, 56], [57, 4],
  [59, 22], [64, 11], [65, 3], [93, 3, 5], [94, 5, 6], [2, 45], [2, 177], [3, 31], [8, 2], [24, 35],
];

// Chapters of Hisn al-Muslim whose first short items rotate as the dua of the day.
DISCOVER.dailyDuaChapters = [1, 2, 7, 8, 10, 33, 34, 42, 68, 69, 95, 105, 128, 129];

// ---------- Occasions in the Islamic calendar (Umm al-Qura calendar: month 1-12, day) ----------
DISCOVER.occasions = [
  { m: 1, d: 1, name: 'Islamic New Year', note: 'The first day of Muharram.' },
  { m: 1, d: 10, name: 'Day of Ashura', note: 'Fasting Ashura expiates the sins of the previous year, and it is recommended to fast the 9th or 11th with it (Muslim).' },
  { m: 9, d: 1, name: 'Ramadan begins', note: 'The month of fasting, the Qur’an and mercy.' },
  { m: 9, d: 21, name: 'Last ten nights of Ramadan', note: 'Seek Laylat al-Qadr in the odd nights of the last ten (Bukhari).' },
  { m: 10, d: 1, name: 'Eid al-Fitr', note: 'Fasting on this day is not permitted (Bukhari and Muslim).' },
  { m: 10, d: 2, name: 'Six days of Shawwal', note: 'Whoever fasts Ramadan then follows it with six days of Shawwal, it is as if he fasted the whole year (Muslim).' },
  { m: 12, d: 1, name: 'First ten days of Dhul Hijjah', note: 'No deeds are more beloved to Allah than righteous deeds in these days (Bukhari).' },
  { m: 12, d: 9, name: 'Day of Arafah', note: 'Fasting Arafah, for those not on Hajj, expiates the previous and the coming year (Muslim).' },
  { m: 12, d: 10, name: 'Eid al-Adha', note: 'The Day of Sacrifice.' },
];

// ---------- Duas for every moment: groups of Hisn al-Muslim chapters ----------
DISCOVER.moments = [
  { id: 'waking', title: 'Waking & sleeping', ar: 'النوم والاستيقاظ', hisn: [2, 1, 28, 29, 30] },
  { id: 'home', title: 'Home & mosque', ar: 'البيت والمسجد', hisn: [7, 8, 9, 10, 11, 12] },
  { id: 'prayer', title: 'Wudu & prayer', ar: 'الوضوء والصلاة', hisn: [5, 6, 17, 18, 19, 20, 21, 23, 24, 25, 26, 27] },
  { id: 'food', title: 'Eating & fasting', ar: 'الطعام والصيام', hisn: [68, 69, 70, 67, 71, 72, 73, 74, 75] },
  { id: 'travel', title: 'Travel', ar: 'السفر', hisn: [94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104] },
  { id: 'hardship', title: 'Worry & hardship', ar: 'الهم والكرب', hisn: [33, 34, 42, 45, 52, 81, 105, 123, 125] },
  { id: 'forgiveness', title: 'Forgiveness & repentance', ar: 'الاستغفار والتوبة', hisn: [128, 43, 84, 85] },
  { id: 'protection', title: 'Protection', ar: 'الحماية والتحصين', hisn: [38, 44, 124, 127, 47, 93, 91] },
  { id: 'illness', title: 'Illness, loss & the grave', ar: 'المرض والموت', hisn: [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] },
  { id: 'weather', title: 'Rain, wind & the moon', ar: 'المطر والريح والهلال', hisn: [60, 61, 62, 63, 64, 65, 66] },
  { id: 'family', title: 'Marriage & children', ar: 'الزواج والأولاد', hisn: [46, 47, 78, 79] },
  { id: 'manners', title: 'Everyday etiquette', ar: 'آداب يومية', hisn: [13, 14, 15, 16, 76, 77, 83, 84, 107, 108, 112, 113, 131] },
  { id: 'hajj', title: 'Hajj & Umrah', ar: 'الحج والعمرة', hisn: [114, 115, 116, 117, 118, 119, 120] },
  { id: 'dhikr', title: 'Remembering Allah', ar: 'فضل الذكر', hisn: [129, 130, 106] },
];

// ---------- Collections: verses from the Qur'an plus a few authored duas, with the Sunnah behind them ----------
DISCOVER.collections = [
  {
    id: 'quran-duas', title: 'Duas from the Qur’an', ar: 'أدعية من القرآن',
    blurb: 'Supplications of the prophets and the righteous, in the words Allah recorded.',
    items: [
      { v: [1, 5, 7] }, { v: [2, 127, 128] }, { v: [2, 201] }, { v: [2, 250] }, { v: [2, 286] }, { v: [3, 8] }, { v: [3, 16] },
      { v: [3, 38] }, { v: [3, 147] }, { v: [3, 191, 194] }, { v: [7, 23] }, { v: [10, 85, 86] }, { v: [12, 101] }, { v: [14, 40, 41] },
      { v: [17, 24] }, { v: [17, 80] }, { v: [18, 10] }, { v: [20, 25, 28] }, { v: [20, 114] }, { v: [21, 83] }, { v: [21, 87] },
      { v: [23, 29] }, { v: [23, 97, 98] }, { v: [23, 118] }, { v: [25, 74] }, { v: [27, 19] }, { v: [28, 16] }, { v: [28, 24] },
      { v: [46, 15] }, { v: [59, 10] }, { v: [66, 8] }, { v: [71, 28] },
    ],
  },
  {
    id: 'protection', title: 'Protection & refuge', ar: 'التحصين',
    blurb: 'The verses and surahs the Prophet ﷺ taught for seeking Allah’s protection.',
    facts: [
      { t: 'Whoever recites Ayat al-Kursi when going to bed, a guardian from Allah stays with him and Satan will not come near him until morning.', s: 'Sahih al-Bukhari' },
      { t: 'Whoever recites the last two verses of Surah al-Baqarah at night, they will be enough for him.', s: 'Sahih al-Bukhari and Sahih Muslim' },
      { t: 'Recite Surah al-Ikhlas and the two Mu’awwidhat (al-Falaq and an-Nas) three times in the morning and in the evening; they will be enough for you against everything.', s: 'Abu Dawud and at-Tirmidhi' },
      { t: 'Nothing stands between the one who recites Ayat al-Kursi after each obligatory prayer and entering Paradise except death.', s: 'an-Nasa’i, Amal al-Yawm wal-Laylah' },
    ],
    items: [{ v: [2, 255] }, { v: [2, 285, 286] }, { v: [112, 1, 4] }, { v: [113, 1, 5] }, { v: [114, 1, 6] }, { v: [23, 97, 98] }],
  },
  {
    id: 'friday', title: 'Friday (Jumu’ah)', ar: 'يوم الجمعة',
    blurb: 'The best day of the week.',
    facts: [
      { t: 'Whoever recites Surah al-Kahf on Friday, a light will shine for him between the two Fridays.', s: 'al-Hakim and al-Bayhaqi' },
      { t: 'Send abundant blessings upon me on Friday.', s: 'Abu Dawud and Ibn Majah' },
      { t: 'On Friday there is an hour in which a Muslim who asks Allah for good while standing in prayer will be given it.', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ surah: 18 }, { v: [18, 1, 10] }, { v: [62, 9, 10] }, { v: [33, 56] }, { hisn: 24 }],
  },
  {
    id: 'ramadan', title: 'Ramadan & Laylat al-Qadr', ar: 'رمضان وليلة القدر',
    blurb: 'The month of fasting, and the night better than a thousand months.',
    facts: [
      { t: 'Whoever fasts Ramadan with faith and seeking reward, his previous sins will be forgiven.', s: 'Sahih al-Bukhari and Sahih Muslim' },
      { t: 'Whoever stands in prayer on Laylat al-Qadr with faith and seeking reward, his previous sins will be forgiven.', s: 'Sahih al-Bukhari and Sahih Muslim' },
      { t: 'Seek Laylat al-Qadr in the odd nights of the last ten nights of Ramadan.', s: 'Sahih al-Bukhari' },
      { t: 'Whoever gives a fasting person something to break his fast with earns the same reward as him, without lessening the fasting person’s reward.', s: 'at-Tirmidhi' },
    ],
    items: [
      { v: [2, 183, 185] }, { v: [2, 186] }, { v: [97, 1, 5] },
      { dua: { ar: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', en: 'O Allah, You are Pardoning and You love to pardon, so pardon me.', tl: 'Allahumma innaka ‘afuwwun tuhibbul-‘afwa fa’fu ‘anni.', src: 'The supplication the Prophet ﷺ taught ‘A’ishah for Laylat al-Qadr: at-Tirmidhi and Ibn Majah', title: 'Dua for Laylat al-Qadr' } },
      { hisn: 67 },
    ],
  },
  {
    id: 'eid', title: 'Eid', ar: 'العيد',
    blurb: 'Takbeer, gratitude and sacrifice.',
    items: [
      { v: [2, 185] }, { v: [22, 34, 37] }, { v: [108, 1, 3] },
      { dua: { ar: 'اللهُ أَكْبَرُ اللهُ أَكْبَرُ لَا إِلَهَ إِلَّا اللهُ، وَاللهُ أَكْبَرُ اللهُ أَكْبَرُ وَلِلَّهِ الْحَمْدُ', en: 'Allah is the Greatest, Allah is the Greatest. There is no god but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.', tl: 'Allahu akbar, Allahu akbar, la ilaha illallah, wallahu akbar, Allahu akbar, wa lillahil-hamd.', src: 'The customary Takbeer of Eid, reported from the Companions (Ibn Abi Shaybah)', title: 'Takbeer of Eid' } },
      { dua: { ar: 'تَقَبَّلَ اللهُ مِنَّا وَمِنْكُمْ', en: 'May Allah accept it from us and from you.', tl: 'Taqabbalallahu minna wa minkum.', src: 'The greeting the Companions exchanged on Eid', title: 'Eid greeting' } },
    ],
  },
  {
    id: 'hajj', title: 'Hajj & the Sacred House', ar: 'الحج والبيت الحرام',
    blurb: 'Verses about the Ka’bah and the pilgrimage, with the supplications of the rites.',
    items: [{ v: [2, 125, 127] }, { v: [3, 96, 97] }, { v: [22, 27, 28] }, { v: [5, 3] }, { hisn: 114 }, { hisn: 118 }],
  },
  {
    id: 'patience', title: 'Patience & hardship', ar: 'الصبر والابتلاء',
    blurb: 'Verses for difficult times.',
    facts: [
      { t: 'How wonderful is the affair of the believer: all of it is good for him. If something good happens to him he is grateful, and that is good for him; if something harmful happens to him he is patient, and that is good for him.', s: 'Sahih Muslim' },
    ],
    items: [{ v: [2, 153, 157] }, { v: [94, 5, 6] }, { v: [65, 3] }, { v: [39, 10] }, { v: [13, 28] }, { v: [9, 51] }, { v: [3, 173] }, { hisn: 33 }, { hisn: 34 }],
  },
  {
    id: 'gratitude', title: 'Gratitude & praise', ar: 'الشكر والحمد',
    blurb: 'Thanking Allah for what we have.',
    items: [{ v: [14, 7] }, { v: [16, 18] }, { v: [27, 40] }, { v: [31, 12] }, { v: [1, 2, 4] }, { hisn: 129 }, { hisn: 130 }],
  },
  {
    id: 'forgiveness', title: 'Forgiveness & mercy', ar: 'المغفرة والرحمة',
    blurb: 'Returning to Allah.',
    facts: [
      { t: 'Every son of Adam sins, and the best of those who sin are those who repent.', s: 'at-Tirmidhi and Ibn Majah' },
    ],
    items: [{ v: [39, 53] }, { v: [3, 135, 136] }, { v: [4, 110] }, { v: [66, 8] }, { v: [25, 70] }, { v: [71, 10, 12] }, { v: [7, 23] }, { hisn: 128 }],
  },
  {
    id: 'knowledge', title: 'Knowledge & guidance', ar: 'العلم والهداية',
    blurb: 'Asking Allah for understanding and the straight path.',
    facts: [
      { t: 'Whoever treads a path seeking knowledge, Allah makes easy for him a path to Paradise.', s: 'Sahih Muslim' },
    ],
    items: [{ v: [20, 114] }, { v: [20, 25, 28] }, { v: [1, 5, 7] }, { v: [3, 8] }, { v: [39, 9] }, { v: [18, 10] }],
  },
  {
    id: 'family', title: 'Parents & family', ar: 'الوالدان والأسرة',
    blurb: 'Kindness to parents and prayers for children and spouses.',
    facts: [
      { t: 'The pleasure of the Lord is in the pleasure of the parent, and the anger of the Lord is in the anger of the parent.', s: 'at-Tirmidhi' },
    ],
    items: [{ v: [17, 23, 24] }, { v: [25, 74] }, { v: [46, 15] }, { v: [14, 40, 41] }, { v: [31, 14, 15] }, { v: [3, 38] }],
  },
];

// ---------- Sunnah fasting ----------
DISCOVER.fasting = [
  { t: 'Mondays and Thursdays', n: 'Deeds are presented to Allah on these days, and the Prophet ﷺ loved to be fasting when his deeds were presented.', s: 'at-Tirmidhi and an-Nasa’i' },
  { t: 'The White Days (13th, 14th and 15th of each month)', n: 'The Prophet ﷺ advised fasting three days every month.', s: 'Sahih al-Bukhari and Sahih Muslim; an-Nasa’i for the White Days' },
  { t: 'Six days of Shawwal', n: 'Whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted the whole year.', s: 'Sahih Muslim' },
  { t: 'The Day of Arafah (9 Dhul Hijjah)', n: 'It expiates the sins of the previous year and the coming year, for those who are not on Hajj.', s: 'Sahih Muslim' },
  { t: 'Ashura (10 Muharram)', n: 'It expiates the sins of the previous year. It is recommended to fast the 9th or the 11th with it.', s: 'Sahih Muslim' },
  { t: 'Muharram', n: 'The best fasting after Ramadan is in Allah’s month of Muharram.', s: 'Sahih Muslim' },
  { t: 'Days on which fasting is not permitted', n: 'The two days of Eid.', s: 'Sahih al-Bukhari and Sahih Muslim' },
];

// ---------- The Forty Hadith of Imam an-Nawawi: titles and plain-English summaries (the Arabic is in data/discover/nawawi.json) ----------
// The summaries are written for this app, not taken from a published translation.
DISCOVER.nawawi = [
  null,
  { t: 'Actions are judged by intentions', s: 'Deeds are only as good as the intention behind them, and each person gets what they intended. Emigrating for Allah and His Messenger is rewarded as such; emigrating for worldly gain or marriage counts only for that.', src: 'Bukhari and Muslim' },
  { t: 'The Hadith of Jibril', s: 'Jibril, appearing as a stranger, asks the Prophet ﷺ about Islam, faith (iman), excellence (ihsan), the Hour and its signs. Islam is the five pillars; iman is the six articles of belief; ihsan is to worship Allah as though you see Him, for even if you do not see Him, He sees you.', src: 'Muslim' },
  { t: 'The five pillars of Islam', s: 'Islam is built on five: the testimony of faith, establishing prayer, giving zakat, pilgrimage to the House, and fasting Ramadan.', src: 'Bukhari and Muslim' },
  { t: 'Creation and the decree', s: 'A human being is formed in the womb in stages, then an angel is sent to breathe in the soul and to record four things: provision, lifespan, deeds, and whether they will be wretched or blessed. Deeds are judged by how they end.', src: 'Bukhari and Muslim' },
  { t: 'Rejecting innovation', s: 'Whoever introduces into this matter of ours something that is not part of it will have it rejected.', src: 'Bukhari and Muslim' },
  { t: 'The lawful and the unlawful are clear', s: 'What is lawful is clear and what is unlawful is clear, and between them are doubtful matters. Whoever avoids doubtful matters protects his religion and honour. In the body is a piece of flesh: if it is sound, the whole body is sound; it is the heart.', src: 'Bukhari and Muslim' },
  { t: 'Religion is sincere advice', s: 'The religion is naseehah (sincerity and sincere advice): to Allah, to His Book, to His Messenger, to the leaders of the Muslims and to their common people.', src: 'Muslim' },
  { t: 'The sanctity of life and property', s: 'Those who testify to the faith, establish prayer and give zakat have their lives and property protected, except by the right of Islam, and their reckoning is with Allah.', src: 'Bukhari and Muslim' },
  { t: 'Do what you are able to', s: 'Avoid what the Prophet ﷺ forbade; do what he commanded as much as you can. Earlier nations were destroyed by their excessive questioning and their disputes with their prophets.', src: 'Bukhari and Muslim' },
  { t: 'Allah accepts only what is pure', s: 'Allah is pure and accepts only what is pure. He commanded the believers as He commanded the messengers: eat of the good things and do righteous deeds. A traveller who raises his hands in dua while his food, drink and clothing are unlawful, how can he be answered?', src: 'Muslim' },
  { t: 'Leave what makes you doubt', s: 'Leave what makes you doubt for what does not make you doubt.', src: 'at-Tirmidhi and an-Nasa’i' },
  { t: 'Leave what does not concern you', s: 'Part of the excellence of a person’s Islam is leaving what does not concern him.', src: 'at-Tirmidhi and Ibn Majah' },
  { t: 'Love for your brother what you love for yourself', s: 'None of you truly believes until he loves for his brother what he loves for himself.', src: 'Bukhari and Muslim' },
  { t: 'The sanctity of a Muslim’s blood', s: 'A Muslim’s blood may not be shed except in three cases: a married person who commits adultery, a life for a life, and one who abandons his religion and leaves the community. Such penalties belong only to the lawful authority and the courts.', src: 'Bukhari and Muslim' },
  { t: 'Speak good or keep silent', s: 'Whoever believes in Allah and the Last Day should speak good or keep silent; should honour his neighbour; and should honour his guest.', src: 'Bukhari and Muslim' },
  { t: 'Do not become angry', s: 'A man asked for advice and the Prophet ﷺ told him, repeatedly: "Do not become angry."', src: 'Bukhari' },
  { t: 'Excellence in everything', s: 'Allah has prescribed excellence (ihsan) in everything. Even when slaughtering, do it well: sharpen the blade and spare the animal suffering.', src: 'Muslim' },
  { t: 'Fear Allah wherever you are', s: 'Be mindful of Allah wherever you are; follow a bad deed with a good one and it will erase it; and treat people with good character.', src: 'at-Tirmidhi' },
  { t: 'Allah will protect those who protect His rights', s: 'Guard Allah and He will guard you. When you ask, ask Allah; when you seek help, seek help from Allah. Even if the whole nation gathered to benefit you, they could only do so by what Allah has written for you. The pens are lifted and the pages are dry.', src: 'at-Tirmidhi' },
  { t: 'Modesty', s: 'Among what people inherited from the words of earlier prophets: "If you feel no shame, do as you wish." Modesty is a guard against doing wrong.', src: 'Bukhari' },
  { t: 'Faith and steadfastness', s: 'A man asked for a statement about Islam he need ask no one else about. The Prophet ﷺ said: "Say, I believe in Allah, then be steadfast."', src: 'Muslim' },
  { t: 'The path to Paradise', s: 'A man asked whether he would enter Paradise if he prayed the obligatory prayers, fasted Ramadan, treated the lawful as lawful and the unlawful as unlawful, and did nothing more. The Prophet ﷺ said yes.', src: 'Muslim' },
  { t: 'Purity is half of faith', s: 'Purity is half of faith. "Alhamdulillah" fills the scale. Prayer is light, charity is proof, patience is illumination, and the Qur’an is a proof for you or against you. Every person starts the day either freeing himself or ruining himself.', src: 'Muslim' },
  { t: 'Allah has forbidden oppression (Hadith Qudsi)', s: 'Allah says: "O My servants, I have forbidden oppression for Myself and made it forbidden among you, so do not oppress one another." All guidance, food and clothing come from Him, so ask Him. Only deeds are recorded and returned; whoever finds good should praise Allah, and whoever finds otherwise should blame only himself.', src: 'Muslim' },
  { t: 'Every good deed is charity', s: 'The Companions said the wealthy take the rewards by giving charity. The Prophet ﷺ replied that every tasbih, takbir, tahmid and tahlil is charity, as are enjoining good and forbidding evil.', src: 'Muslim' },
  { t: 'Charity every day', s: 'Every joint of a person owes charity each day: judging justly between two people, helping someone onto their mount, a good word, every step towards prayer, and removing harm from the road.', src: 'Bukhari and Muslim' },
  { t: 'Righteousness is good character', s: 'Righteousness is good character, and sin is what stirs in your heart and what you dislike people finding out about.', src: 'Muslim' },
  { t: 'Hold fast to the Sunnah', s: 'The Prophet ﷺ gave a moving sermon: fear Allah, listen and obey, and hold fast to his Sunnah and that of the rightly guided caliphs. Beware of newly invented matters in religion.', src: 'Abu Dawud and at-Tirmidhi' },
  { t: 'The doors of goodness', s: 'Mu’adh asked for a deed that enters him into Paradise. The Prophet ﷺ named the pillars of Islam, then the doors of goodness (fasting, charity, night prayer), and told him to guard his tongue.', src: 'at-Tirmidhi' },
  { t: 'Respect the limits Allah has set', s: 'Allah has set obligations, so do not neglect them; set limits, so do not transgress them; forbidden things, so do not violate them; and has been silent about some things out of mercy, so do not go searching for them.', src: 'ad-Daraqutni' },
  { t: 'Detachment from the world', s: 'A man asked for a deed that would make Allah and people love him. The Prophet ﷺ said: "Be detached from the world and Allah will love you; be detached from what people have and people will love you."', src: 'Ibn Majah' },
  { t: 'No harm and no reciprocating harm', s: 'There is to be no harming and no reciprocating harm: a foundation of Islamic ethics and law.', src: 'Ibn Majah and ad-Daraqutni' },
  { t: 'The burden of proof', s: 'If people were given whatever they claimed, some would claim the wealth and blood of others. The burden of proof is on the claimant, and the oath is on the one who denies.', src: 'al-Bayhaqi' },
  { t: 'Changing what is wrong', s: 'Whoever sees something wrong should change it with his hand; if he cannot, then with his tongue; if he cannot, then with his heart, and that is the weakest of faith.', src: 'Muslim' },
  { t: 'Brotherhood in Islam', s: 'Do not envy, deceive, hate or turn away from one another. A Muslim is the brother of a Muslim: he does not wrong him, abandon him, lie to him or look down on him. Piety is here (the chest). The blood, wealth and honour of a Muslim are sacred.', src: 'Muslim' },
  { t: 'Relieving others’ hardship', s: 'Whoever relieves a believer of a worldly hardship, Allah relieves him of a hardship on the Day of Resurrection. Whoever eases the burden of a debtor, conceals a Muslim’s fault, or seeks knowledge, Allah will ease, conceal and ease the path to Paradise for him. Allah helps His servant while he helps his brother.', src: 'Muslim' },
  { t: 'Allah multiplies good deeds', s: 'Whoever intends a good deed but does not do it, Allah records one full good deed; if he does it, ten up to seven hundred times or more. Whoever intends a bad deed and does not do it, Allah records a full good deed; if he does it, one bad deed.', src: 'Bukhari and Muslim' },
  { t: 'Drawing near to Allah', s: 'Allah says: nothing brings My servant closer to Me than what I made obligatory for him, and My servant keeps drawing nearer to Me with voluntary deeds until I love him. When I love him, I am his hearing, sight, hand and foot; if he asks Me, I give him, and if he seeks refuge in Me, I protect him.', src: 'Bukhari' },
  { t: 'Allah overlooks mistakes', s: 'Allah has pardoned for my nation mistakes, forgetfulness and what they are forced to do.', src: 'Ibn Majah and al-Bayhaqi' },
  { t: 'Be like a stranger in this world', s: 'Be in this world as though you were a stranger or a traveller. Ibn Umar added: when evening comes do not wait for morning, and when morning comes do not wait for evening; take from your health for your illness and from your life for your death.', src: 'Bukhari' },
  { t: 'Desires follow what the Prophet brought', s: 'None of you truly believes until his desires follow what the Prophet ﷺ brought.', src: 'Related by an-Nawawi in al-Hujjah with a sound chain' },
  { t: 'The vastness of Allah’s forgiveness (Hadith Qudsi)', s: 'Allah says: "O son of Adam, as long as you call on Me and hope in Me, I will forgive you whatever you have done. If your sins reached the clouds of the sky and you asked My forgiveness, I would forgive you. If you came to Me with an earth-full of sins but met Me not associating anything with Me, I would bring you an earth-full of forgiveness."', src: 'at-Tirmidhi' },
];

// ---------- The 99 Names of Allah ----------
// [Arabic, transliteration, meaning]
DISCOVER.names = [
  ['اللَّهُ', 'Allah', 'The One God, the Lord of all that exists'],
  ['الرَّحْمَنُ', 'Ar-Rahman', 'The Most Gracious'],
  ['الرَّحِيمُ', 'Ar-Rahim', 'The Most Merciful'],
  ['الْمَلِكُ', 'Al-Malik', 'The King, the Sovereign'],
  ['الْقُدُّوسُ', 'Al-Quddus', 'The Most Holy'],
  ['السَّلَامُ', 'As-Salam', 'The Source of Peace'],
  ['الْمُؤْمِنُ', 'Al-Mu’min', 'The Giver of Security'],
  ['الْمُهَيْمِنُ', 'Al-Muhaymin', 'The Guardian, the Watcher'],
  ['الْعَزِيزُ', 'Al-‘Aziz', 'The Almighty'],
  ['الْجَبَّارُ', 'Al-Jabbar', 'The Compeller, the Restorer'],
  ['الْمُتَكَبِّرُ', 'Al-Mutakabbir', 'The Supreme in Greatness'],
  ['الْخَالِقُ', 'Al-Khaliq', 'The Creator'],
  ['الْبَارِئُ', 'Al-Bari’', 'The Maker of all things'],
  ['الْمُصَوِّرُ', 'Al-Musawwir', 'The Fashioner of forms'],
  ['الْغَفَّارُ', 'Al-Ghaffar', 'The Ever-Forgiving'],
  ['الْقَهَّارُ', 'Al-Qahhar', 'The All-Subduing'],
  ['الْوَهَّابُ', 'Al-Wahhab', 'The Bestower'],
  ['الرَّزَّاقُ', 'Ar-Razzaq', 'The Provider'],
  ['الْفَتَّاحُ', 'Al-Fattah', 'The Opener, the Judge'],
  ['الْعَلِيمُ', 'Al-‘Alim', 'The All-Knowing'],
  ['الْقَابِضُ', 'Al-Qabid', 'The Withholder'],
  ['الْبَاسِطُ', 'Al-Basit', 'The Expander'],
  ['الْخَافِضُ', 'Al-Khafid', 'The Abaser'],
  ['الرَّافِعُ', 'Ar-Rafi’', 'The Exalter'],
  ['الْمُعِزُّ', 'Al-Mu’izz', 'The Giver of honour'],
  ['الْمُذِلُّ', 'Al-Mudhill', 'The Giver of dishonour'],
  ['السَّمِيعُ', 'As-Sami’', 'The All-Hearing'],
  ['الْبَصِيرُ', 'Al-Basir', 'The All-Seeing'],
  ['الْحَكَمُ', 'Al-Hakam', 'The Judge'],
  ['الْعَدْلُ', 'Al-‘Adl', 'The Utterly Just'],
  ['اللَّطِيفُ', 'Al-Latif', 'The Subtle, the Most Gentle'],
  ['الْخَبِيرُ', 'Al-Khabir', 'The All-Aware'],
  ['الْحَلِيمُ', 'Al-Halim', 'The Forbearing'],
  ['الْعَظِيمُ', 'Al-‘Azim', 'The Magnificent'],
  ['الْغَفُورُ', 'Al-Ghafur', 'The Great Forgiver'],
  ['الشَّكُورُ', 'Ash-Shakur', 'The Most Appreciative'],
  ['الْعَلِيُّ', 'Al-‘Ali', 'The Most High'],
  ['الْكَبِيرُ', 'Al-Kabir', 'The Most Great'],
  ['الْحَفِيظُ', 'Al-Hafiz', 'The Preserver'],
  ['الْمُقِيتُ', 'Al-Muqit', 'The Sustainer'],
  ['الْحَسِيبُ', 'Al-Hasib', 'The Reckoner'],
  ['الْجَلِيلُ', 'Al-Jalil', 'The Majestic'],
  ['الْكَرِيمُ', 'Al-Karim', 'The Most Generous'],
  ['الرَّقِيبُ', 'Ar-Raqib', 'The Watchful'],
  ['الْمُجِيبُ', 'Al-Mujib', 'The Responsive'],
  ['الْوَاسِعُ', 'Al-Wasi’', 'The All-Encompassing'],
  ['الْحَكِيمُ', 'Al-Hakim', 'The All-Wise'],
  ['الْوَدُودُ', 'Al-Wadud', 'The Most Loving'],
  ['الْمَجِيدُ', 'Al-Majid', 'The Glorious'],
  ['الْبَاعِثُ', 'Al-Ba’ith', 'The Resurrector'],
  ['الشَّهِيدُ', 'Ash-Shahid', 'The Witness'],
  ['الْحَقُّ', 'Al-Haqq', 'The Truth'],
  ['الْوَكِيلُ', 'Al-Wakil', 'The Trustee, the Disposer of affairs'],
  ['الْقَوِيُّ', 'Al-Qawi', 'The All-Strong'],
  ['الْمَتِينُ', 'Al-Matin', 'The Firm'],
  ['الْوَلِيُّ', 'Al-Wali', 'The Protecting Friend'],
  ['الْحَمِيدُ', 'Al-Hamid', 'The Praiseworthy'],
  ['الْمُحْصِي', 'Al-Muhsi', 'The Counter, who accounts for everything'],
  ['الْمُبْدِئُ', 'Al-Mubdi’', 'The Originator'],
  ['الْمُعِيدُ', 'Al-Mu’id', 'The Restorer'],
  ['الْمُحْيِي', 'Al-Muhyi', 'The Giver of life'],
  ['الْمُمِيتُ', 'Al-Mumit', 'The Bringer of death'],
  ['الْحَيُّ', 'Al-Hayy', 'The Ever-Living'],
  ['الْقَيُّومُ', 'Al-Qayyum', 'The Self-Subsisting, the Sustainer of all'],
  ['الْوَاجِدُ', 'Al-Wajid', 'The Finder, who lacks nothing'],
  ['الْمَاجِدُ', 'Al-Majid', 'The Noble'],
  ['الْوَاحِدُ', 'Al-Wahid', 'The One'],
  ['الصَّمَدُ', 'As-Samad', 'The Eternal Refuge'],
  ['الْقَادِرُ', 'Al-Qadir', 'The All-Able'],
  ['الْمُقْتَدِرُ', 'Al-Muqtadir', 'The All-Powerful'],
  ['الْمُقَدِّمُ', 'Al-Muqaddim', 'The Expediter, who brings forward'],
  ['الْمُؤَخِّرُ', 'Al-Mu’akhkhir', 'The Delayer, who puts back'],
  ['الْأَوَّلُ', 'Al-Awwal', 'The First'],
  ['الْآخِرُ', 'Al-Akhir', 'The Last'],
  ['الظَّاهِرُ', 'Az-Zahir', 'The Manifest'],
  ['الْبَاطِنُ', 'Al-Batin', 'The Hidden'],
  ['الْوَالِي', 'Al-Wali', 'The Governor'],
  ['الْمُتَعَالِي', 'Al-Muta’ali', 'The Supreme, the Exalted'],
  ['الْبَرُّ', 'Al-Barr', 'The Source of all goodness'],
  ['التَّوَّابُ', 'At-Tawwab', 'The Ever-Accepting of repentance'],
  ['الْمُنْتَقِمُ', 'Al-Muntaqim', 'The Avenger'],
  ['الْعَفُوُّ', 'Al-‘Afuww', 'The Pardoner'],
  ['الرَّءُوفُ', 'Ar-Ra’uf', 'The Most Kind'],
  ['مَالِكُ الْمُلْكِ', 'Malik-ul-Mulk', 'The Owner of all sovereignty'],
  ['ذُو الْجَلَالِ وَالْإِكْرَامِ', 'Dhul-Jalali wal-Ikram', 'The Lord of Majesty and Generosity'],
  ['الْمُقْسِطُ', 'Al-Muqsit', 'The Equitable'],
  ['الْجَامِعُ', 'Al-Jami’', 'The Gatherer'],
  ['الْغَنِيُّ', 'Al-Ghani', 'The Self-Sufficient'],
  ['الْمُغْنِي', 'Al-Mughni', 'The Enricher'],
  ['الْمَانِعُ', 'Al-Mani’', 'The Preventer'],
  ['الضَّارُّ', 'Ad-Darr', 'The Distresser'],
  ['النَّافِعُ', 'An-Nafi’', 'The Benefactor'],
  ['النُّورُ', 'An-Nur', 'The Light'],
  ['الْهَادِي', 'Al-Hadi', 'The Guide'],
  ['الْبَدِيعُ', 'Al-Badi’', 'The Incomparable Originator'],
  ['الْبَاقِي', 'Al-Baqi', 'The Everlasting'],
  ['الْوَارِثُ', 'Al-Warith', 'The Inheritor of all'],
  ['الرَّشِيدُ', 'Ar-Rashid', 'The Guide to the right path'],
  ['الصَّبُورُ', 'As-Sabur', 'The Most Patient'],
];
