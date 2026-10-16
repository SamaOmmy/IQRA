'use strict';
// Days of the Islamic calendar: sunnah occasions, moments of the sira and turning points in history.
// Dates of historical events are the ones given by the classical historians; where scholars differ, the note says so.
module.exports = {
  occasions: [
    { m: 1, d: 1, name: 'Islamic New Year', note: 'The first day of Muharram, a sacred month. The calendar counts from the Hijrah.', story: 'h-hijri' },
    { m: 1, d: 10, name: 'Day of Ashura', note: 'Fasting Ashura expiates the sins of the previous year, and it is recommended to fast the 9th or 11th with it (Muslim). The Prophet ﷺ found the Jews of Madinah fasting it because Allah saved Musa on that day (Bukhari).' },
    { m: 3, d: 12, name: 'The Prophet’s arrival in Madinah and his passing (traditional date)', note: 'The classical historians give 12 Rabi‘ al-Awwal for his arrival in Madinah in 1 AH, and for his passing in 11 AH. His birth is also commonly given on this date, though scholars differ about the day.', story: 'sira-hijrah' },
    { m: 4, d: 24, name: 'Battle of Hattin (583 AH)', note: 'On 24 Rabi‘ ath-Thani 583 AH (4 July 1187 CE), Salah ad-Din defeated the Crusader army and opened the way to Jerusalem.', story: 'h-salahuddin' },
    { m: 5, d: 20, name: 'Fall of Constantinople (857 AH)', note: 'On 20 Jumada al-Ula 857 AH (29 May 1453 CE) the city fell to Sultan Muhammad al-Fatih, as the Prophet ﷺ had foretold to his community.', story: 'h-constantinople' },
    { m: 6, d: 22, name: 'Passing of Abu Bakr (13 AH)', note: 'The first caliph died on 22 Jumada ath-Thaniyah, two years and about three months after the Prophet ﷺ.', story: 'c-abu-bakr' },
    { m: 7, d: 1, name: 'Rajab begins', note: 'One of the four sacred months in which Allah forbade fighting and wrongdoing (Qur’an 9:36).' },
    { m: 7, d: 27, name: 'The Night Journey, as remembered by many Muslims', note: 'Many Muslims remember the Isra’ and Mi‘raj on 27 Rajab. Scholars say that the exact night is not established by an authentic report. Salah ad-Din entered Jerusalem on this date in 583 AH.', story: 'sira-isra' },
    { m: 8, d: 1, name: 'Sha‘ban begins', note: '‘A’ishah said that the Prophet ﷺ fasted more in Sha‘ban than in any other month (Bukhari and Muslim).' },
    { m: 9, d: 1, name: 'Ramadan begins', note: 'The month of fasting, the Qur’an and mercy.' },
    { m: 9, d: 15, name: 'Birth of al-Hasan (3 AH)', note: 'The Prophet’s first grandson by Fatimah and ‘Ali, born in the middle of Ramadan in the third year, according to most historians.', story: 's-hasan' },
    { m: 9, d: 17, name: 'Battle of Badr (2 AH)', note: 'On 17 Ramadan, the Muslims, about three hundred strong, met Quraysh at Badr, and Allah gave them victory on the day He called the Day of Criterion (Qur’an 8:41).', story: 'sira-badr' },
    { m: 9, d: 20, name: 'The conquest of Makkah (8 AH)', note: 'The Prophet ﷺ entered Makkah in Ramadan of the eighth year, most commonly dated to the 20th, and forgave its people.', story: 'sira-conquest' },
    { m: 9, d: 21, name: 'Passing of ‘Ali (40 AH)', note: 'The fourth caliph was struck while praying in the mosque of Kufa and died of the wound on 21 Ramadan.', story: 'c-ali' },
    { m: 9, d: 25, name: '‘Ayn Jalut (658 AH)', note: 'On 25 Ramadan 658 AH (3 September 1260 CE), the Mamluk army under Qutuz and Baybars defeated a Mongol army in Palestine.', story: 'h-ain-jalut' },
    { m: 9, d: 27, name: 'The 27th night of Ramadan', note: 'Ubayy ibn Ka‘b used to swear that Laylat al-Qadr was the 27th night (Muslim). Its exact night is hidden: seek it in the odd nights of the last ten.' },
    { m: 10, d: 7, name: 'Battle of Uhud (3 AH)', note: 'On Saturday 7 Shawwal, the Muslims met Quraysh at the foot of Mount Uhud. Hamzah was killed, and the Prophet ﷺ was wounded.', story: 'sira-uhud' },
    { m: 11, d: 1, name: 'Dhul-Qa‘dah begins', note: 'A sacred month. In it the Prophet ﷺ made three of his four ‘Umrahs, including Hudaybiyyah in 6 AH.', story: 'sira-hudaybiyyah' },
    { m: 12, d: 8, name: 'Day of Tarwiyah', note: 'The pilgrims go to Mina and spend the day and night there.' },
    { m: 12, d: 9, name: 'The Farewell Sermon (10 AH)', note: 'On the Day of Arafah in the tenth year, the Prophet ﷺ spoke to more than a hundred thousand Muslims in the valley of ‘Uranah.', story: 'sira-farewell' },
    { m: 12, d: 11, name: 'Days of Tashriq', note: 'The 11th, 12th and 13th are days of eating, drinking and remembering Allah (Muslim). Fasting on them is not allowed except for those who could not offer the hady.' },
    { m: 12, d: 18, name: 'Martyrdom of ‘Uthman (35 AH)', note: 'The third caliph was killed in his house in Madinah in Dhul-Hijjah of 35 AH, while reciting the Qur’an, according to the classical historians.', story: 'c-uthman' },
    { m: 12, d: 26, name: '‘Umar is struck (23 AH)', note: 'The second caliph was stabbed while leading the dawn prayer, and died three days later. He was buried at the beginning of Muharram.', story: 'c-umar' },
  ],
};
