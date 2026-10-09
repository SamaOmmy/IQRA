'use strict';
// More collections: verses gathered by theme, each with the Sunnah behind it. Verse text comes from the app's own Qur'an data.
DISCOVER.collections.push(
  {
    id: 'trust', title: 'Trust in Allah (tawakkul)', ar: 'التوكل على الله',
    blurb: 'Verses on relying on Allah after doing your part.',
    facts: [
      { t: 'If you relied on Allah as He should be relied upon, He would provide for you as He provides for the birds: they go out hungry in the morning and return full.', s: 'Sunan at-Tirmidhi, hasan; Sunan Ibn Majah' },
    ],
    items: [{ v: [3, 159] }, { v: [3, 173, 174] }, { v: [8, 2] }, { v: [9, 51] }, { v: [14, 11, 12] }, { v: [65, 2, 3] }, { v: [25, 58] }, { v: [39, 38] }, { v: [11, 123] }],
  },
  {
    id: 'night', title: 'The night prayer', ar: 'قيام الليل',
    blurb: 'The believers who rise in the night, in the words of the Qur’an.',
    facts: [
      { t: 'The best prayer after the obligatory prayers is the prayer in the night.', s: 'Sahih Muslim' },
      { t: 'Our Lord descends to the lowest heaven in the last third of the night and says: Who calls upon Me that I may answer him? Who asks Me that I may give him? Who seeks My forgiveness that I may forgive him?', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ v: [17, 79] }, { v: [73, 1, 7] }, { v: [25, 63, 64] }, { v: [32, 15, 17] }, { v: [51, 15, 18] }, { v: [39, 9] }, { v: [76, 25, 26] }, { v: [3, 17] }],
  },
  {
    id: 'mercy', title: 'The mercy of Allah', ar: 'رحمة الله',
    blurb: 'Verses of hope for the one who has fallen short.',
    facts: [
      { t: 'When Allah decreed the creation, He wrote in a book that is with Him above the Throne: My mercy prevails over My wrath.', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ v: [39, 53, 54] }, { v: [7, 156] }, { v: [6, 54] }, { v: [12, 87] }, { v: [15, 56] }, { v: [40, 7] }, { v: [4, 110] }, { v: [2, 186] }, { v: [50, 16] }, { v: [20, 82] }],
  },
  {
    id: 'reflection', title: 'Reflecting on creation', ar: 'التفكر في الخلق',
    blurb: 'Verses that invite you to look at the sky, the earth and yourself.',
    facts: [
      { t: 'The Prophet ﷺ used to recite the last ten verses of Surah Al ‘Imran when he woke at night.', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ v: [3, 190, 194] }, { v: [2, 164] }, { v: [30, 20, 25] }, { v: [88, 17, 20] }, { v: [16, 10, 18] }, { v: [67, 3, 4] }, { v: [51, 20, 21] }, { v: [41, 53] }],
  },
  {
    id: 'character', title: 'Character and manners', ar: 'مكارم الأخلاق',
    blurb: 'Verses on how a believer speaks, behaves and treats others.',
    facts: [
      { t: 'The most beloved of you to me, and the nearest to me on the Day of Resurrection, are those with the best character.', s: 'Sunan at-Tirmidhi, hasan' },
      { t: 'I was sent only to perfect the best of character.', s: 'Musnad Ahmad; al-Adab al-Mufrad (sound)' },
    ],
    items: [{ v: [49, 11, 13] }, { v: [31, 17, 19] }, { v: [25, 63, 67] }, { v: [17, 36] }, { v: [16, 90] }, { v: [4, 36] }, { v: [3, 134] }, { v: [41, 34, 35] }, { v: [23, 1, 11] }],
  },
  {
    id: 'justice', title: 'Justice', ar: 'العدل',
    blurb: 'Standing for fairness, even against yourself.',
    facts: [
      { t: 'The just will be on pulpits of light beside the Most Merciful, on His right: those who are just in their rulings, with their families and in what they are given charge of.', s: 'Sahih Muslim' },
    ],
    items: [{ v: [4, 135] }, { v: [5, 8] }, { v: [16, 90] }, { v: [4, 58] }, { v: [57, 25] }, { v: [49, 9] }, { v: [6, 152] }],
  },
  {
    id: 'brotherhood', title: 'Brotherhood and unity', ar: 'الأخوة والوحدة',
    blurb: 'The bond between believers.',
    facts: [
      { t: 'The believers in their mutual love, mercy and compassion are like one body: when one part complains, the whole body responds with sleeplessness and fever.', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ v: [3, 103] }, { v: [49, 10] }, { v: [49, 12] }, { v: [8, 46] }, { v: [9, 71] }, { v: [5, 2] }, { v: [59, 9, 10] }],
  },
  {
    id: 'spending', title: 'Giving and spending', ar: 'الإنفاق في سبيل الله',
    blurb: 'Verses on charity, generosity and the use of wealth.',
    facts: [
      { t: 'Charity does not decrease wealth.', s: 'Sahih Muslim' },
      { t: 'Every day two angels descend: one says, O Allah, give the one who spends something in return; the other says, O Allah, give the one who withholds destruction.', s: 'Sahih al-Bukhari and Sahih Muslim' },
    ],
    items: [{ v: [2, 261, 262] }, { v: [2, 267] }, { v: [2, 274] }, { v: [3, 92] }, { v: [57, 7] }, { v: [64, 16, 17] }, { v: [92, 5, 7] }, { v: [76, 8, 9] }],
  },
  {
    id: 'ease', title: 'Hope and ease', ar: 'اليسر والفرج',
    blurb: 'Verses to hold on to in a hard time.',
    facts: [
      { t: 'Know that victory comes with patience, relief with affliction, and ease with hardship.', s: 'Musnad Ahmad, from Ibn ‘Abbas (sound)' },
    ],
    items: [{ v: [94, 1, 8] }, { v: [93, 1, 5] }, { v: [65, 7] }, { v: [2, 286] }, { v: [2, 185] }, { v: [12, 87] }, { v: [39, 10] }, { v: [3, 139] }],
  },
  {
    id: 'akhirah', title: 'This life and the next', ar: 'الدنيا والآخرة',
    blurb: 'Reminders that this world is a passing stop on the way.',
    facts: [
      { t: 'Be in this world as though you were a stranger or a traveller.', s: 'Sahih al-Bukhari, from Ibn ‘Umar' },
      { t: 'Remember often the destroyer of pleasures, which is death.', s: 'Sunan at-Tirmidhi and an-Nasa’i' },
    ],
    items: [{ v: [3, 185] }, { v: [57, 20] }, { v: [18, 45, 46] }, { v: [29, 64] }, { v: [55, 26, 27] }, { v: [62, 8] }, { v: [31, 33] }, { v: [102, 1, 8] }],
  },
);
