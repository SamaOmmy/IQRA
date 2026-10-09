// Second batch of curated hadith for the Hadith Library (see hadith-curation.js for the format and how the Arabic is verified).
module.exports = [
  // ---- Worship
  { id: 'two-cool-prayers', book: 'bukhari', n: 574, phrase: 'من صلى البردين دخل الجنة', theme: 'worship', title: 'The two cool prayers',
    en: 'Whoever prays the two cool prayers, Fajr and ‘Asr, will enter Paradise.', src: 'Sahih al-Bukhari, narrated by Abu Musa' },
  { id: 'after-adhan', book: 'bukhari', n: 614, phrase: 'من قال حين يسمع النداء', from: 'من قال حين يسمع النداء', to: 'شفاعتي يوم القيامة', theme: 'dua', title: 'What to say after the call to prayer',
    en: 'Whoever says, when he hears the call: "O Allah, Lord of this perfect call and the prayer about to be established, grant Muhammad the intercession and the excellence, and raise him to the praised station You promised him," my intercession will be due for him on the Day of Resurrection.', src: 'Sahih al-Bukhari, narrated by Jabir' },
  { id: 'fajr-sunnah', book: 'muslim', n: 1688, phrase: 'ركعتا الفجر خير من الدنيا وما فيها', theme: 'worship', title: 'Two rak’ahs before Fajr',
    en: 'The two rak’ahs before the Fajr prayer are better than the world and everything in it.', src: 'Sahih Muslim, narrated by ‘A’ishah' },
  { id: 'fajr-protection', book: 'muslim', n: 1493, phrase: 'من صلى الصبح فهو في ذمة الله', theme: 'worship', title: 'Under Allah’s protection',
    en: 'Whoever prays the dawn prayer is under Allah’s protection. So do not let Allah demand from you anything of His protection, for whoever He demands it from, He overtakes him and throws him on his face into the Fire of Hell.', src: 'Sahih Muslim, narrated by Jundub' },
  { id: 'fasting-shield', book: 'bukhari', n: 1894, phrase: 'الصيام جنة', theme: 'worship', title: 'Fasting is a shield',
    en: 'Fasting is a shield. So let the fasting person not speak obscenely or act ignorantly, and if someone fights or insults him, let him say twice: "I am fasting." By the One in whose hand is my soul, the breath of the fasting person’s mouth is better to Allah than the fragrance of musk. He leaves his food, his drink and his desire for My sake. Fasting is for Me and I reward it, and every good deed is rewarded ten times over.', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },
  { id: 'fasting-speech', book: 'bukhari', n: 1903, phrase: 'من لم يدع قول الزور والعمل به', theme: 'worship', title: 'Fasting is more than hunger',
    en: 'Whoever does not give up false speech and acting upon it, Allah has no need of his giving up food and drink.', src: 'Sahih al-Bukhari, narrated by Abu Hurayrah' },
  { id: 'suhoor', book: 'bukhari', n: 1923, phrase: 'تسحروا فإن في السحور بركة', theme: 'worship', title: 'Blessing in the pre-dawn meal',
    en: 'Eat the pre-dawn meal, for there is blessing in the pre-dawn meal.', src: 'Sahih al-Bukhari, narrated by Anas' },

  // ---- Dua and dhikr
  { id: 'most-common-dua', book: 'bukhari', n: 4522, phrase: 'اللهم ربنا آتنا في الدنيا حسنة', theme: 'dua', title: 'The Prophet’s most frequent dua',
    en: 'The supplication the Prophet ﷺ made most often was: "O Allah, our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire." (It is the verse 2:201.)', src: 'Sahih al-Bukhari, narrated by Anas' },
  { id: 'master-of-istighfar', book: 'bukhari', n: 6306, phrase: 'سيد الاستغفار', theme: 'dua', title: 'The master of seeking forgiveness',
    en: 'The master of seeking forgiveness is to say: "O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You." The Prophet ﷺ added that whoever says it with conviction in the day and dies before evening is of the people of Paradise, and likewise at night.', src: 'Sahih al-Bukhari, narrated by Shaddad ibn Aws' },
  { id: 'protection-formula', book: 'abudawud', n: 5088, phrase: 'بسم الله الذي لا يضر مع اسمه شيء', from: 'من قال بسم الله الذي لا يضر', to: 'حتى يمسي', theme: 'dua', title: 'Words of protection for morning and evening',
    en: 'Whoever says three times "In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing," will not be struck by a sudden calamity until the morning (if said in the evening), and whoever says it three times in the morning will not be struck by sudden calamity until the evening.', src: 'Sunan Abi Dawud, narrated by ‘Uthman, and at-Tirmidhi (graded sound)' },
  { id: 'dua-for-absent', book: 'muslim', n: 6929, phrase: 'دعوة المرء المسلم لأخيه بظهر الغيب', theme: 'dua', title: 'Praying for your brother in secret',
    en: 'A Muslim’s supplication for his brother in his absence is answered. Beside his head is an angel appointed to him; whenever he prays for something good for his brother, the angel says: "Amin, and may you have the same."', src: 'Sahih Muslim, narrated by Abu al-Darda’' },
  { id: 'guidance-piety', book: 'muslim', n: 6904, phrase: 'اللهم إني أسألك الهدى والتقى والعفاف والغنى', theme: 'dua', title: 'Four things to ask for',
    en: 'O Allah, I ask You for guidance, piety, chastity and self-sufficiency.', src: 'Sahih Muslim, narrated by ‘Abdullah ibn Mas’ud' },
  { id: 'three-answered-duas', book: 'abudawud', n: 1536, phrase: 'ثلاث دعوات مستجابات', theme: 'dua', title: 'Three duas that are answered',
    en: 'Three supplications are answered, with no doubt about them: the supplication of a parent, the supplication of a traveller and the supplication of the oppressed.', src: 'Sunan Abi Dawud, narrated by Abu Hurayrah (graded hasan)' },

  // ---- Family
  { id: 'best-to-family', book: 'tirmidhi', n: 3895, phrase: 'خيركم خيركم لأهله', from: 'خيركم خيركم لأهله', to: 'فدعوه', theme: 'family', title: 'The best to their families',
    en: 'The best of you are the best to their families, and I am the best of you to my family. And when your companion dies, leave him (do not speak ill of him).', src: 'Sunan at-Tirmidhi, narrated by ‘A’ishah' },
  { id: 'parents-pleasure', book: 'tirmidhi', n: 1899, phrase: 'رضا الرب في رضا الوالد', theme: 'family', title: 'The pleasure of the parent',
    en: 'The Lord’s pleasure is in the pleasure of the parent, and the Lord’s displeasure is in the displeasure of the parent.', src: 'Sunan at-Tirmidhi, narrated by ‘Abdullah ibn ‘Amr (graded sound)' },

  // ---- Brotherhood and manners
  { id: 'like-a-building', book: 'bukhari', n: 2446, phrase: 'المؤمن للمؤمن كالبنيان', theme: 'brotherhood', title: 'Like a building',
    en: 'The believer to the believer is like a building, each part strengthening the other.', src: 'Sahih al-Bukhari, narrated by Abu Musa' },
  { id: 'one-body', book: 'muslim', n: 6586, phrase: 'مثل المؤمنين في توادهم وتراحمهم', theme: 'brotherhood', title: 'Like one body',
    en: 'The believers, in their mutual love, mercy and compassion, are like one body: when one part complains, the rest of the body responds with sleeplessness and fever.', src: 'Sahih Muslim, narrated by al-Nu’man ibn Bashir' },
  { id: 'in-his-need', book: 'bukhari', n: 2442, phrase: 'من كان في حاجة أخيه كان الله في حاجته', theme: 'brotherhood', title: 'Allah is in the need of the one who helps',
    en: 'A Muslim is the brother of a Muslim: he does not wrong him and does not hand him over. Whoever is in the need of his brother, Allah is in his need; whoever relieves a Muslim of a hardship, Allah will relieve him of a hardship on the Day of Resurrection; and whoever covers a Muslim, Allah will cover him on the Day of Resurrection.', src: 'Sahih al-Bukhari, narrated by Ibn ‘Umar' },
  { id: 'cheerful-face', book: 'muslim', n: 6690, phrase: 'لا تحقرن من المعروف شيئا', theme: 'brotherhood', title: 'Never belittle a good deed',
    en: 'Never belittle any good, even if it is only meeting your brother with a cheerful face.', src: 'Sahih Muslim, narrated by Abu Dharr' },
  { id: 'every-kindness', book: 'bukhari', n: 6021, phrase: 'كل معروف صدقة', theme: 'charity', title: 'Every kindness is charity',
    en: 'Every act of kindness is charity.', src: 'Sahih al-Bukhari, narrated by Jabir' },
  { id: 'thank-people', book: 'abudawud', n: 4811, phrase: 'لا يشكر الله من لا يشكر الناس', theme: 'manners', title: 'Thanking people',
    en: 'Whoever does not thank people does not thank Allah.', src: 'Sunan Abi Dawud and at-Tirmidhi, narrated by Abu Hurayrah' },
  { id: 'repay-kindness', book: 'abudawud', n: 1672, phrase: 'من صنع إليكم معروفا فكافئوه', theme: 'manners', title: 'Repaying a kindness',
    en: 'Whoever seeks refuge in Allah, give him refuge; whoever asks in Allah’s name, give to him; whoever invites you, accept; and whoever does you a kindness, repay him. If you do not find anything to repay him with, pray for him until you feel you have repaid him.', src: 'Sunan Abi Dawud, narrated by Ibn ‘Umar (graded sound)' },
  { id: 'modesty-brings-good', book: 'bukhari', n: 6117, phrase: 'الحياء لا يأتي إلا بخير', theme: 'manners', title: 'Modesty brings only good',
    en: 'Modesty brings nothing but good.', src: 'Sahih al-Bukhari, narrated by ‘Imran ibn Husayn' },

  // ---- Work and honest dealing
  { id: 'no-cheating', book: 'muslim', n: 283, phrase: 'من غشنا فليس منا', theme: 'trade', title: 'Whoever cheats us',
    en: 'Whoever carries weapons against us is not one of us, and whoever cheats us is not one of us.', src: 'Sahih Muslim, narrated by Abu Hurayrah' },
  { id: 'easy-going-seller', book: 'bukhari', n: 2076, phrase: 'رحم الله رجلا سمحا إذا باع', theme: 'trade', title: 'Easy-going in business',
    en: 'May Allah have mercy on a man who is easy-going when he sells, when he buys and when he asks for what is owed to him.', src: 'Sahih al-Bukhari, narrated by Jabir' },
  { id: 'worker-wages', book: 'ibnmajah', n: 2443, phrase: 'أعطوا الأجير أجره قبل أن يجف عرقه', theme: 'trade', title: 'Pay the worker promptly',
    en: 'Give the worker his wages before his sweat dries.', src: 'Sunan Ibn Majah, narrated by Ibn ‘Umar (graded sound by some scholars)' },

  // ---- Hardship and the Hereafter
  { id: 'trials-expiate', book: 'bukhari', n: 5641, phrase: 'ما يصيب المسلم من نصب ولا وصب', theme: 'hardship', title: 'Even a thorn',
    en: 'No fatigue, illness, worry, sadness, harm or distress befalls a Muslim, even a thorn that pricks him, except that Allah expiates some of his sins with it.', src: 'Sahih al-Bukhari, narrated by Abu Sa’id and Abu Hurayrah' },
  { id: 'remember-death', book: 'tirmidhi', n: 2307, phrase: 'أكثروا ذكر هاذم اللذات', theme: 'hardship', title: 'The destroyer of pleasures',
    en: 'Increase your remembrance of the destroyer of pleasures, which is death.', src: 'Sunan at-Tirmidhi and an-Nasa’i, narrated by Abu Hurayrah' },

  // ---- Faith
  { id: 'sweetness-of-faith', book: 'bukhari', n: 16, phrase: 'ثلاث من كن فيه وجد حلاوة الإيمان', theme: 'faith', title: 'The sweetness of faith',
    en: 'Whoever has three things finds the sweetness of faith: that Allah and His Messenger are dearer to him than anything else; that he loves a person only for Allah’s sake; and that he hates to return to disbelief as he hates to be thrown into the Fire.', src: 'Sahih al-Bukhari, narrated by Anas' },
];
