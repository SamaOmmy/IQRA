// Third batch of curated hadith for the Hadith Library (see hadith-curation.js for the format and how the Arabic is verified).
module.exports = [
  // ---- The Qur'an
  { id: 'quran-intercede', book: 'muslim', n: 1874, phrase: 'اقرءوا القرآن فإنه يأتي يوم القيامة شفيعا لأصحابه', from: 'اقرءوا القرآن فإنه يأتي يوم القيامة', to: 'شفيعا لأصحابه', theme: 'quran', title: 'It will intercede for its companions',
    en: 'Recite the Qur’an, for it will come on the Day of Resurrection as an intercessor for its companions.', src: 'Sahih Muslim, narrated by Abu Umamah' },
  { id: 'skilled-quran', book: 'muslim', n: 1862, phrase: 'الماهر بالقرآن مع السفرة', theme: 'quran', title: 'Two rewards for the one who struggles',
    en: 'The one who is skilled in the Qur’an will be with the noble and obedient angels who carry the scrolls. And the one who recites it haltingly, finding it difficult, will have two rewards.', src: 'Sahih Muslim, narrated by ‘A’ishah' },

  // ---- Knowledge
  { id: 'seek-knowledge', book: 'ibnmajah', n: 224, phrase: 'طلب العلم فريضة', from: 'طلب العلم فريضة على كل مسلم', to: 'على كل مسلم', theme: 'knowledge', title: 'Seeking knowledge is a duty',
    en: 'Seeking knowledge is an obligation upon every Muslim.', src: 'Sunan Ibn Majah, narrated by Anas (graded hasan by a number of scholars)' },
  { id: 'understand-religion', book: 'bukhari', n: 71, phrase: 'من يرد الله به خيرا يفقهه في الدين', from: 'من يرد الله به خيرا', to: 'يفقهه في الدين', theme: 'knowledge', title: 'When Allah wants good for someone',
    en: 'When Allah wants good for someone, He gives him understanding of the religion.', src: 'Sahih al-Bukhari, narrated by Mu’awiyah' },

  // ---- Mercy and gentleness
  { id: 'merciful', book: 'abudawud', n: 4941, phrase: 'الراحمون يرحمهم الرحمن', theme: 'mercy', title: 'Those on earth and the One in heaven',
    en: 'The merciful are shown mercy by the Most Merciful. Show mercy to those on earth, and the One who is above the heavens will show mercy to you.', src: 'Sunan Abi Dawud and at-Tirmidhi, narrated by ‘Abdullah ibn ‘Amr (graded sound)' },
  { id: 'allah-gentle', book: 'muslim', n: 6601, phrase: 'إن الله رفيق يحب الرفق', theme: 'mercy', title: 'Allah is gentle',
    en: 'O ‘A’ishah, Allah is gentle and loves gentleness. He gives for gentleness what He does not give for harshness, and what He does not give for anything else.', src: 'Sahih Muslim, narrated by ‘A’ishah' },

  // ---- Manners
  { id: 'belly-vessel', book: 'tirmidhi', n: 2380, phrase: 'ما ملأ آدمي وعاء شرا من بطن', from: 'ما ملأ آدمي وعاء شرا من بطن', to: 'وثلث لنفسه', theme: 'manners', title: 'Moderation in eating',
    en: 'No human being fills a vessel worse than his stomach. A few bites to keep his back straight are enough for the son of Adam. If he must eat more, then a third for his food, a third for his drink and a third for his breathing.', src: 'Sunan at-Tirmidhi and Sunan Ibn Majah, narrated by al-Miqdam ibn Ma’dikarib (graded sound)' },
  { id: 'bitten-twice', book: 'bukhari', n: 6133, phrase: 'لا يلدغ المؤمن من جحر', theme: 'manners', title: 'Learn from the first sting',
    en: 'A believer is not stung twice from the same hole.', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },
  { id: 'spread-salam', book: 'muslim', n: 194, phrase: 'أفشوا السلام بينكم', theme: 'brotherhood', title: 'Spread the greeting of peace',
    en: 'You will not enter Paradise until you believe, and you will not believe until you love one another. Shall I tell you something that, if you do it, you will love one another? Spread the greeting of peace among yourselves.', src: 'Sahih Muslim, narrated by Abu Hurayrah' },

  // ---- Family
  { id: 'your-mother', book: 'muslim', n: 6500, phrase: 'من أحق الناس بحسن صحابتي', from: 'من أحق الناس بحسن صحابتي', to: 'ثم أبوك', theme: 'family', title: 'Your mother, then your mother, then your mother',
    en: 'A man asked: "O Messenger of Allah, who is most deserving of my good companionship?" He said: "Your mother." The man said: "Then who?" He said: "Then your mother." He said: "Then who?" He said: "Then your mother." He said: "Then who?" He said: "Then your father."', src: 'Sahih Muslim, narrated by Abu Hurayrah (also Sahih al-Bukhari)' },
  { id: 'orphan-sponsor', book: 'bukhari', n: 5304, phrase: 'أنا وكافل اليتيم في الجنة', theme: 'family', title: 'Beside the Prophet in Paradise',
    en: 'I and the one who looks after an orphan will be in Paradise like this: and he pointed with his index and middle fingers, separating them slightly.', src: 'Sahih al-Bukhari, narrated by Sahl ibn Sa’d' },

  // ---- Charity
  { id: 'good-word', book: 'bukhari', n: 2989, phrase: 'الكلمة الطيبة صدقة', from: 'كل سلامى من الناس عليه صدقة', to: 'عن الطريق صدقة', theme: 'charity', title: 'Every joint owes charity each day',
    en: 'Every joint of a person owes a charity every day the sun rises. Judging justly between two people is charity. Helping a man with his mount, lifting him onto it or lifting his belongings onto it, is charity. A good word is charity. Every step taken towards the prayer is charity. And removing harm from the road is charity.', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },
  { id: 'half-date', book: 'bukhari', n: 6023, phrase: 'اتقوا النار ولو بشق تمرة', theme: 'charity', title: 'Even half a date',
    en: 'Protect yourselves from the Fire, even with half a date; and if you cannot find that, then with a good word.', src: 'Sahih al-Bukhari, narrated by ‘Adi ibn Hatim' },
  { id: 'plant-tree', book: 'bukhari', n: 2320, phrase: 'ما من مسلم يغرس غرسا', theme: 'charity', title: 'Planting is charity',
    en: 'There is no Muslim who plants a tree or sows a crop, and a bird, a person or an animal eats from it, except that it is charity for him.', src: 'Sahih al-Bukhari, narrated by Anas' },
  { id: 'two-angels', book: 'bukhari', n: 1442, phrase: 'اللهم أعط منفقا خلفا', from: 'ما من يوم يصبح العباد فيه', to: 'اللهم أعط ممسكا تلفا', theme: 'charity', title: 'The two angels each morning',
    en: 'Every morning two angels descend. One says: "O Allah, give the one who spends something in return." The other says: "O Allah, give the one who withholds destruction."', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },

  // ---- Worship
  { id: 'dearest-deeds', book: 'muslim', n: 7122, phrase: 'أحب العمل إلى الله أدومه', from: 'أحب العمل إلى الله أدومه', to: 'وإن قل', theme: 'worship', title: 'The most beloved deed',
    en: 'The most beloved deed to Allah is the one done most regularly, even if it is small.', src: 'Sahih Muslim' },
  { id: 'purity-half', book: 'muslim', n: 534, phrase: 'الطهور شطر الإيمان', from: 'الطهور شطر الإيمان', to: 'لك أو عليك', theme: 'worship', title: 'Purity is half of faith',
    en: 'Purity is half of faith. "Alhamdulillah" fills the scale, and "SubhanAllah" and "Alhamdulillah" together fill, or each fills, what is between the heavens and the earth. Prayer is light, charity is proof, patience is illumination, and the Qur’an is an argument for you or against you.', src: 'Sahih Muslim, narrated by Abu Malik al-Ash’ari' },
  { id: 'feed-fasting', book: 'tirmidhi', n: 807, phrase: 'من فطر صائما كان له مثل أجره', theme: 'worship', title: 'Feeding someone who fasts',
    en: 'Whoever feeds a fasting person will have a reward like his, without that reducing the fasting person’s reward at all.', src: 'Sunan at-Tirmidhi, narrated by Zayd ibn Khalid al-Juhani (graded sound)' },
  { id: 'five-prayers-river', book: 'bukhari', n: 528, phrase: 'أرأيتم لو أن نهرا بباب أحدكم', from: 'أرأيتم لو أن نهرا بباب أحدكم', to: 'يمحو الله بها الخطايا', theme: 'worship', title: 'The five prayers are like a river',
    en: 'If there were a river at the door of one of you, and he bathed in it five times every day, what would you say? Would any dirt remain on him? They said: "No dirt would remain." He said: "That is like the five prayers: through them Allah wipes away sins."', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },

  // ---- Dua and dhikr
  { id: 'living-dead', book: 'bukhari', n: 6407, phrase: 'مثل الذي يذكر ربه', from: 'مثل الذي يذكر ربه', to: 'الحي والميت', theme: 'dua', title: 'The living and the dead',
    en: 'The example of the one who remembers his Lord and the one who does not is like that of the living and the dead.', src: 'Sahih al-Bukhari, narrated by Abu Musa' },
  { id: 'blessing-ten', book: 'muslim', n: 849, phrase: 'من صلى علي صلاة صلى الله عليه بها عشرا', from: 'من صلى علي صلاة', to: 'عشرا', theme: 'dua', title: 'One blessing, ten in return',
    en: 'Whoever sends one blessing upon me, Allah will send ten blessings upon him.', src: 'Sahih Muslim, narrated by ‘Abdullah ibn ‘Amr' },
  { id: 'dua-worry', book: 'bukhari', n: 6369, phrase: 'اللهم إني أعوذ بك من الهم والحزن', from: 'اللهم إني أعوذ بك من الهم والحزن', to: 'وغلبة الرجال', theme: 'dua', title: 'Refuge from worry and debt',
    en: 'O Allah, I seek refuge in You from worry and grief, from weakness and laziness, from miserliness and cowardice, from the burden of debt and from being overpowered by men.', src: 'Sahih al-Bukhari, narrated by Anas' },
  { id: 'refuge-words', book: 'muslim', n: 6878, phrase: 'أعوذ بكلمات الله التامات من شر ما خلق', from: 'من نزل منزلا', to: 'من منزله ذلك', theme: 'dua', title: 'When you stop at a place',
    en: 'Whoever stops at a place and says "I seek refuge in the perfect words of Allah from the evil of what He created", nothing will harm him until he leaves that place.', src: 'Sahih Muslim, narrated by Khawlah bint Hakim' },
  { id: 'help-dhikr', book: 'abudawud', n: 1522, phrase: 'اللهم أعني على ذكرك وشكرك وحسن عبادتك', from: 'اللهم أعني على ذكرك', to: 'حسن عبادتك', theme: 'dua', title: 'Help me to remember You',
    en: 'O Allah, help me to remember You, to thank You and to worship You well. The Prophet ﷺ advised Mu’adh to say this after every prayer.', src: 'Sunan Abi Dawud and an-Nasa’i, narrated by Mu’adh ibn Jabal (graded sound)' },

  // ---- Faith and hardship
  { id: 'world-prison', book: 'muslim', n: 7417, phrase: 'الدنيا سجن المؤمن', theme: 'hardship', title: 'This world and the next',
    en: 'This world is a prison for the believer and a paradise for the disbeliever. (Scholars explain that, compared with what awaits the believer in the Hereafter, this world is a place of restraint and effort.)', src: 'Sahih Muslim, narrated by Abu Hurayrah' },
  { id: 'trial-believer', book: 'tirmidhi', n: 2399, phrase: 'ما يزال البلاء بالمؤمن', from: 'ما يزال البلاء بالمؤمن', to: 'عليه خطيئة', theme: 'hardship', title: 'Trials that cleanse',
    en: 'Trials continue to befall the believing man and the believing woman in their person, children and wealth until they meet Allah with no sin upon them.', src: 'Sunan at-Tirmidhi, narrated by Abu Hurayrah (graded hasan sahih)' },
  { id: 'great-reward-trial', book: 'tirmidhi', n: 2396, phrase: 'إن عظم الجزاء مع عظم البلاء', from: 'إن عظم الجزاء', to: 'فله السخط', theme: 'hardship', title: 'Great reward comes with great trial',
    en: 'The greatness of the reward comes with the greatness of the trial. When Allah loves a people, He tests them. Whoever is content has His contentment, and whoever is displeased has His displeasure.', src: 'Sunan at-Tirmidhi and Sunan Ibn Majah, narrated by Anas (graded hasan)' },
];
