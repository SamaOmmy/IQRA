'use strict';
// Stories of the prophets and other narratives from the Qur'an. Written for IQRA from the Qur'an itself (and, where marked,
// from hadith in Sahih al-Bukhari or Sahih Muslim). Each story points to the verses it comes from, which the app shows in full.
// p: paragraphs, l: lessons, v: verses [surah, firstAyah, lastAyah?], src: where it is reported.

DISCOVER.shelves = [
  { id: 'prophets', title: 'Stories of the Prophets', ar: 'قصص الأنبياء', blurb: 'The messengers Allah sent, in the order the Qur’an lets us follow them.' },
  { id: 'quran', title: 'Tales from the Qur’an', ar: 'قصص القرآن', blurb: 'People, places and moments the Qur’an tells us about, each with a lesson for today.' },
  { id: 'sira', title: 'The Life of the Prophet ﷺ', ar: 'السيرة النبوية', blurb: 'From the Year of the Elephant to his passing, step by step.' },
  { id: 'companions', title: 'The Companions', ar: 'الصحابة', blurb: 'Ordinary people changed by faith, and what they did with it.' },
  { id: 'situations', title: 'Teachings in Real Moments', ar: 'مواقف نبوية', blurb: 'What the Prophet ﷺ said and did when something actually happened.' },
];
DISCOVER.stories = [];

DISCOVER.stories.push(
  {
    id: 'adam', shelf: 'prophets', title: 'Adam and the first test', ar: 'آدم',
    p: [
      'Allah told the angels He was placing a successor on the earth. He created Adam from clay, taught him the names of things, and commanded the angels to prostrate to him. All did, except Iblis, who refused out of pride: "I am better than him."',
      'Adam and his wife were placed in Paradise and told to eat freely, but not to approach one tree. Satan whispered to them, promising a life that never ends, and they ate. Realising what they had done, they did not blame each other or argue. They turned to Allah: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers."',
      'Allah accepted their repentance and sent them to the earth with guidance for all who would follow.',
    ],
    l: ['Pride was the first sin; humility is the way back.', 'Everyone slips. What matters is turning to Allah quickly instead of making excuses.', 'The earth was never a punishment: it is where guidance and purpose begin.'],
    v: [[2, 30, 39], [7, 11, 25]], src: 'Qur’an 2:30–39, 7:11–25, 20:115–123',
  },
  {
    id: 'idris', shelf: 'prophets', title: 'Idris, the truthful', ar: 'إدريس',
    p: [
      'The Qur’an mentions Idris in two short verses. He was a truthful man and a prophet, and Allah raised him to a high station.',
      'Though little is told, the description is enough: truthfulness and prophethood together are what the Qur’an remembers him for.',
    ],
    l: ['A person can be remembered for one quality done sincerely.', 'Truthfulness is the first mark of a prophet, and a standard for us.'],
    v: [[19, 56, 57]], src: 'Qur’an 19:56–57, 21:85–86',
  },
  {
    id: 'nuh', shelf: 'prophets', title: 'Nuh and the Ark', ar: 'نوح',
    p: [
      'Nuh called his people to worship Allah alone, night and day, in public and in private, for 950 years. Only a few believed. The leaders mocked him: "We see no one following you except the lowest of us." He answered that he would never drive away the believers, whoever they were.',
      'When Allah told him no more would believe, he began building an ark on dry land, and passing people laughed. Then the flood came. Nuh called to his son to board; the son said he would climb a mountain. The wave came between them and the son was among the drowned.',
      'Nuh asked about his son, and Allah replied that he was not of his family in faith, for his deeds were not righteous. The ark came to rest on Mount Judi, and the earth was told to swallow its water.',
    ],
    l: ['Keep calling people with patience, even when the results are small.', 'Guidance belongs to Allah: not even a prophet’s own son is guaranteed.', 'Ties of faith count more than ties of blood.'],
    v: [[11, 25, 48], [71, 1, 10]], src: 'Qur’an 11:25–49, 29:14, 71:1–28',
  },
  {
    id: 'hud', shelf: 'prophets', title: 'Hud and the people of ‘Ad', ar: 'هود',
    p: [
      'The people of ‘Ad were famed for their strength and for towering buildings. They forgot who gave them that strength and asked, "Who is mightier than us in power?" Hud, one of their own, told them to worship Allah and thank Him.',
      'They called him foolish. Hud answered calmly: "I put my trust in Allah, my Lord and your Lord. There is no creature but He holds it by the forelock." When their warning came, it was a roaring wind that blew for seven nights and eight days until the people lay like fallen palm trunks.',
    ],
    l: ['Strength and skill are gifts to be thanked for, not boasted about.', 'A believer can stay calm when others threaten, because his trust is in Allah.'],
    v: [[11, 50, 60], [41, 15, 16]], src: 'Qur’an 7:65–72, 11:50–60, 41:15–16, 69:6–8',
  },
  {
    id: 'salih', shelf: 'prophets', title: 'Salih and the she-camel', ar: 'صالح',
    p: [
      'The people of Thamud carved homes into the mountains and lived in comfort. Salih called them to worship Allah. They asked for a sign, so Allah sent a she-camel with a share of the water on her day and the people’s on theirs. He told them not to harm her.',
      'A group of them killed her anyway. Salih gave them three days, and then a mighty cry struck them and they were left lifeless in their homes.',
    ],
    l: ['A sign from Allah is a test of how we treat what we are given.', 'Comfort and technology do not protect a people who turn their backs on Allah.'],
    v: [[7, 73, 79], [26, 141, 159]], src: 'Qur’an 7:73–79, 11:61–68, 26:141–159',
  },
  {
    id: 'ibrahim', shelf: 'prophets', title: 'Ibrahim, the friend of Allah', ar: 'إبراهيم',
    p: [
      'Ibrahim searched for the truth by reason. He looked at a star, then the moon, then the sun, and set each aside because they set. He declared: "I have turned my face to the One who created the heavens and the earth." He asked his father and his people why they worshipped statues that could neither hear nor help.',
      'One day when the town was away, he broke the idols and left the largest. When they asked who did it, he pointed to the big one and told them to ask it. They were stunned, then furious, and threw him into a great fire. Allah said: "O fire, be coolness and safety upon Ibrahim."',
      'Later he left his wife Hajar and infant Ismail in a barren valley by Allah’s command, and was tested with the command to sacrifice his son. Both submitted, and Allah ransomed the boy with a great sacrifice. Together Ibrahim and Ismail raised the foundations of the Kaaba and prayed: "Our Lord, accept this from us."',
    ],
    l: ['Faith grows from honest reflection and then from complete submission.', 'When you obey Allah, He turns even fire into safety.', 'Make dua for what you build, and for the generations after you.'],
    v: [[6, 75, 79], [21, 51, 70], [37, 99, 111], [2, 127, 129]], src: 'Qur’an 6:74–79, 21:51–70, 37:83–113, 2:124–129, 14:35–41',
  },
  {
    id: 'ismail-hajar', shelf: 'prophets', title: 'Hajar, Ismail and Zamzam', ar: 'هاجر وإسماعيل',
    p: [
      'Ibrahim left Hajar and baby Ismail in a valley with no people, water or plants, with only a bag of dates and a skin of water. When he turned to go, Hajar asked, "Did Allah command you to do this?" He said yes. She replied, "Then He will not let us be lost."',
      'When the water ran out and her son cried with thirst, she ran seven times between the hills of Safa and Marwa, looking for help. Then she heard a voice, and at Ismail’s feet the spring of Zamzam appeared. A passing tribe, Jurhum, saw birds circling over water and settled there with her permission, and Makkah began.',
      'This account is reported in Sahih al-Bukhari, narrated by Ibn ‘Abbas.',
    ],
    l: ['Her trust that Allah would not abandon her was met with a spring that still flows today.', 'The walking between Safa and Marwa in Hajj remembers a mother’s effort.', 'Do your part, and keep your trust in Allah.'],
    v: [[14, 37]], src: 'Sahih al-Bukhari (Ibn ‘Abbas); Qur’an 14:37',
  },
  {
    id: 'lut', shelf: 'prophets', title: 'Lut and the cities of the plain', ar: 'لوط',
    p: [
      'Lut was sent to a people who openly committed a shameful act that no one before them had done. He warned them to fear Allah and reminded them that he asked for no reward.',
      'They answered by threatening to expel him and his family for wanting to stay clean. Angels came in the form of guests, told Lut to leave with his believing family before dawn, and warned that his wife, who sided with the wrongdoers, would not be saved. Then the town was overturned and rained upon.',
    ],
    l: ['Calling people to what is right can bring hostility, but it is still a duty.', 'Being close to a righteous person does not save someone who chooses the other side.'],
    v: [[7, 80, 84], [11, 77, 83]], src: 'Qur’an 7:80–84, 11:77–83, 26:160–175',
  },
  {
    id: 'yusuf', shelf: 'prophets', title: 'Yusuf, the best of stories', ar: 'يوسف',
    p: [
      'As a boy, Yusuf dreamed of eleven stars, the sun and the moon bowing to him. His father Ya’qub told him to keep it from his brothers, who were already jealous. They threw him into a well and told their father a wolf had eaten him. Ya’qub said, "Patience is beautiful."',
      'A caravan found Yusuf and sold him in Egypt. In the household of a noble he grew up, and when the lady of the house tried to seduce him he said, "I seek refuge in Allah." He ran for the door and was falsely imprisoned instead. In prison he kept calling to Allah and interpreted dreams, and when the king dreamed of seven fat cows eaten by seven thin ones, Yusuf explained the coming famine and was made keeper of the stores.',
      'Years later his brothers came for grain. He recognised them; they did not recognise him. When he revealed himself and they feared his reaction, he said, "No blame upon you today. May Allah forgive you." The dream of his childhood came true.',
    ],
    l: ['Beautiful patience trusts that Allah’s plan is bigger than the pit you are in.', 'Integrity under temptation is heroic, and Allah rewards it.', 'Forgiveness from a position of power is true nobility.'],
    v: [[12, 4, 6], [12, 23, 24], [12, 92, 93], [12, 100]], src: 'Qur’an, Surah Yusuf (12) in full',
  },
  {
    id: 'ayyub', shelf: 'prophets', title: 'Ayyub and patience', ar: 'أيوب',
    p: [
      'Ayyub was a prophet who lost his health, his wealth and his family. For a long time he endured, never complaining against Allah. At last he called out quietly: "Indeed adversity has touched me, and You are the Most Merciful of the merciful."',
      'Allah answered at once. He told him to strike the ground with his foot and drink and wash from the spring that appeared. Health returned, and Allah gave back his family and as many again.',
    ],
    l: ['Dua is not the opposite of patience. Ayyub made it while still patient.', 'Allah’s help can come from the very ground under your feet.'],
    v: [[21, 83, 84], [38, 41, 44]], src: 'Qur’an 21:83–84, 38:41–44',
  },
  {
    id: 'shuayb', shelf: 'prophets', title: 'Shu’ayb and honest trade', ar: 'شعيب',
    p: [
      'The people of Madyan cheated in business, giving short measure and weight. Shu’ayb told them: give full measure, do not spread corruption, and what Allah leaves you is better for you if you are believers.',
      'They mocked his prayers and threatened to stone him. When their warning came, the earthquake found them in their homes. Shu’ayb left them with the words: "I conveyed to you the messages of my Lord and advised you."',
    ],
    l: ['Honesty in weights, prices and promises is part of worship.', 'Quick profit from cheating is not worth the loss of barakah.'],
    v: [[11, 84, 95], [7, 85, 93]], src: 'Qur’an 7:85–93, 11:84–95, 26:176–191',
  },
  {
    id: 'musa', shelf: 'prophets', title: 'Musa and Fir’awn', ar: 'موسى',
    p: [
      'Fir’awn was killing the newborn sons of Bani Israil. Musa’s mother was inspired to place her baby in a basket on the river and trust Allah, who promised to return him. He floated to Fir’awn’s own household, who adopted him, and his mother was brought back as his nurse.',
      'As a young man, Musa struck a man who died and fled to Madyan. There he watered the flocks of two women without asking anything, then sat in the shade and said, "My Lord, I am in need of whatever good You send down to me." He worked for years for the women’s father and married.',
      'On the way back, he saw a fire by the mountain. A voice told him: "I am your Lord." Allah gave him signs, including the staff, and sent him with his brother Harun to Fir’awn. After the magicians themselves believed, Fir’awn chased the Israelites to the sea, which Allah split. Musa and his people crossed; Fir’awn drowned.',
    ],
    l: ['Trust Allah with what you love most; He can return it better.', 'Helping others without asking for anything can be the key to your own provision.', 'No tyrant, however powerful, can overcome Allah’s plan.'],
    v: [[28, 7, 13], [28, 23, 28], [20, 9, 24], [26, 61, 68]], src: 'Qur’an 20:9–98, 26:10–68, 28:3–43',
  },
  {
    id: 'dawud-sulayman', shelf: 'prophets', title: 'Dawud and Sulayman', ar: 'داود وسليمان',
    p: [
      'A young Dawud faced the giant Jalut (Goliath) in battle and, by Allah’s permission, defeated him. Allah gave him kingship and the Zabur, made iron soft in his hands, and the mountains and birds joined him in praise. When he realised a case he judged had been a test, he asked forgiveness, fell down in prostration and turned back to Allah.',
      'His son Sulayman was given command of wind and jinn, and understanding of the speech of birds and ants. Passing an ant colony, he smiled at the ant’s warning and prayed: "My Lord, enable me to be grateful for Your favour." When Bilqis, queen of Sheba, came to see his kingdom, she saw the truth in his message and submitted: "My Lord, I have wronged myself, and I submit with Sulayman to Allah."',
    ],
    l: ['Power in the hands of the thankful is a blessing; Dawud and Sulayman used it to turn back to Allah.', 'No creature is too small to deserve attention and care.'],
    v: [[27, 18, 19], [38, 17, 26], [27, 40, 44]], src: 'Qur’an 2:251, 21:78–82, 27:15–44, 38:17–40',
  },
  {
    id: 'yunus', shelf: 'prophets', title: 'Yunus in the belly of the fish', ar: 'يونس',
    p: [
      'Yunus called his people, but when they would not respond he left them in anger, before Allah gave him permission. On a loaded ship, lots were drawn and he was thrown into the sea, and a great fish swallowed him.',
      'In the darkness of the night, the sea and the fish’s belly, he called out: "There is no god but You. Glory to You. I was among the wrongdoers." Allah rescued him. His people, in the meantime, had believed, and Allah let them live in ease for a time.',
    ],
    l: ['Admit your mistake and return, even from the deepest dark.', 'This dua is reported to relieve distress (at-Tirmidhi), and Allah says He saves believers this way.', 'Do not give up on people. They may believe after you leave.'],
    v: [[21, 87, 88], [37, 139, 148], [10, 98]], src: 'Qur’an 21:87–88, 37:139–148, 10:98',
  },
  {
    id: 'zakariyya-yahya', shelf: 'prophets', title: 'Zakariyya and Yahya', ar: 'زكريا ويحيى',
    p: [
      'Zakariyya was very old, his wife could not have children, and he feared for what would happen to the faith after him. Seeing the provision that appeared in Maryam’s prayer-room, he went and called quietly to his Lord: "My Lord, my bones have weakened and my hair is gray, yet never was I disappointed in my prayer to You."',
      'The angels gave him news of a son, Yahya, whom Allah described as noble, chaste and a prophet from among the righteous.',
    ],
    l: ['No situation is too late for Allah’s mercy.', 'A quiet dua from the heart reaches Allah.'],
    v: [[19, 2, 9], [3, 37, 41]], src: 'Qur’an 3:37–41, 19:1–15, 21:89–90',
  },
  {
    id: 'maryam-isa', shelf: 'prophets', title: 'Maryam and ‘Isa', ar: 'مريم وعيسى',
    p: [
      'Maryam was devoted to worship from childhood and raised in the care of Zakariyya. One day an angel came to her in human form and told her she would have a son, ‘Isa, with no father: it is easy for Allah, who says "Be" and it is.',
      'In labour, alone beside a palm trunk, she cried in distress. A voice reassured her: shake the trunk, eat, drink and be comforted. When her people accused her, she pointed to the baby. He spoke in the cradle: "Indeed I am the servant of Allah. He has given me the Scripture and made me a prophet."',
      '‘Isa called to the worship of Allah, and by Allah’s permission healed the blind, healed the leper and gave life to the dead. The Qur’an says he was not killed or crucified: Allah raised him to Himself.',
    ],
    l: ['‘Isa is among the greatest messengers, a servant of Allah.', 'When Maryam was most alone, Allah sent comfort and provision.', 'Trust and purity are rewarded in unexpected ways.'],
    v: [[19, 16, 33], [3, 42, 51]], src: 'Qur’an 3:42–59, 19:16–36, 5:110–118',
  },
);

DISCOVER.stories.push(
  {
    id: 'cave', shelf: 'quran', title: 'The People of the Cave', ar: 'أصحاب الكهف',
    p: [
      'A group of young men lived under a ruler who forced people to worship others besides Allah. They left their town and took refuge in a cave, praying: "Our Lord, grant us mercy from Yourself and prepare for us right guidance in our affair."',
      'Allah caused them to sleep for years. When they woke, they thought it had been a day or part of a day. One went to buy food with an old coin, and the townspeople realised who they were. By then the people of the town had come to believe in Allah.',
    ],
    l: ['Protect your faith even if it means walking away from comfort.', 'Allah protects those who flee to Him.'],
    v: [[18, 9, 16], [18, 19, 20]], src: 'Qur’an 18:9–26. Surah al-Kahf is recommended on Fridays.',
  },
  {
    id: 'dhul-qarnayn', shelf: 'quran', title: 'Dhul-Qarnayn, the just ruler', ar: 'ذو القرنين',
    p: [
      'Allah gave Dhul-Qarnayn power and a way to everything. He travelled to the west and the east, and he judged fairly: to those who wronged he gave punishment, and to those who believed and did good he gave good words and ease.',
      'He met a people who said that Ya’juj and Ma’juj were spreading corruption, and asked him to build a barrier. He asked only for their strong hands, not payment, and built it from iron and molten copper. He said: "This is a mercy from my Lord."',
    ],
    l: ['Real power is serving people and giving credit to Allah.', 'He refused payment and asked for effort instead.'],
    v: [[18, 83, 91], [18, 95, 98]], src: 'Qur’an 18:83–98',
  },
  {
    id: 'khidr', shelf: 'quran', title: 'Musa and al-Khidr', ar: 'موسى والخضر',
    p: [
      'Musa was asked, "Who is the most knowledgeable?" and replied that it was he. Allah told him of a servant who had knowledge from Allah that he did not. Musa set out to meet him, and asked to follow him and learn. Al-Khidr told him he would not have the patience, but agreed on one condition: do not ask about anything until I explain.',
      'The man damaged a boat. He struck down a boy. He rebuilt a wall for a town that refused them food. Musa could not hold his tongue each time. Finally Khidr explained: the boat belonged to poor men and a king was seizing good boats; the boy would have burdened his believing parents with disbelief; the wall protected the treasure of two orphans.',
    ],
    l: ['What looks like harm may hide mercy; we see only part of the picture.', 'Even a great prophet was humbled by the limits of his knowledge.'],
    v: [[18, 60, 70], [18, 79, 82]], src: 'Qur’an 18:60–82; the setting is in Sahih al-Bukhari',
  },
  {
    id: 'luqman', shelf: 'quran', title: 'Luqman’s advice to his son', ar: 'لقمان',
    p: [
      'Allah gave Luqman wisdom and told him to be grateful. He is remembered for the advice he gave his son: do not associate anything with Allah, for that is a great wrong; if a thing weighs as little as a mustard seed, hidden in a rock or in the heavens or earth, Allah will bring it forth.',
      'He told his son to establish prayer, enjoin what is right and forbid what is wrong, and be patient. He added: do not turn your cheek in contempt to people or walk the earth arrogantly, be moderate in your pace, and lower your voice.',
    ],
    l: ['Good character is part of wisdom.', 'Parents’ advice to children is a gift that should be recorded.'],
    v: [[31, 13, 19]], src: 'Qur’an 31:12–19',
  },
  {
    id: 'qarun', shelf: 'quran', title: 'Qarun and his treasures', ar: 'قارون',
    p: [
      'Qarun was of the people of Musa but he was arrogant. Allah gave him so many treasures that its keys alone were a burden for a group of strong men. His people told him: do not exult, seek the home of the Hereafter through what Allah gave you, and do good as Allah has done good to you.',
      'He answered, "I was given it only because of knowledge I have." When he came out before the people in splendour, those who wanted worldly life wished for what he had. Then Allah caused the earth to swallow him and his house.',
    ],
    l: ['Wealth is a test. Credit for it belongs to Allah.', 'What looked enviable can vanish, and those who valued knowledge of Allah were right.'],
    v: [[28, 76, 82]], src: 'Qur’an 28:76–82',
  },
  {
    id: 'garden-owners', shelf: 'quran', title: 'The Owners of the Garden', ar: 'أصحاب الجنة',
    p: [
      'The Qur’an tells of owners of a rich garden. They swore they would pick its fruit early in the morning, and they agreed that no poor person should enter it that day. They did not say "if Allah wills."',
      'During the night, a calamity from Allah went over the garden while they slept. In the morning, they went to find it like a harvested field. Then the most just of them said, "Did I not tell you to glorify Allah?" They said, "Glory to our Lord, we were wrongdoers," and turned to Allah in regret.',
    ],
    l: ['Charity is a right of the poor on your wealth.', 'Say "if Allah wills" over every plan.'],
    v: [[68, 17, 33]], src: 'Qur’an 68:17–33',
  },
  {
    id: 'elephant', shelf: 'quran', title: 'The Year of the Elephant', ar: 'أصحاب الفيل',
    p: [
      'Abraha, the Abyssinian governor of Yemen, built a great church and wanted the Arabs to make pilgrimage there instead of the Kaaba. He marched on Makkah with an army and elephants. The Quraysh, unable to face him, moved to the hills, and ‘Abd al-Muttalib told him the House has a Lord who protects it.',
      'When the army turned to enter, flocks of birds appeared, dropping hard clay stones on it, and left it like eaten straw. That year, around 570 CE, is when the Prophet ﷺ was born.',
    ],
    l: ['Allah protects His sacred House.', 'The year of Muhammad’s ﷺ birth began with a sign against arrogance.'],
    v: [[105, 1, 5]], src: 'Qur’an, Surah al-Fil (105)',
  },
  {
    id: 'ukhdud', shelf: 'quran', title: 'The Boy, the King and the Trench', ar: 'أصحاب الأخدود',
    p: [
      'Allah mentions the People of the Trench in Surah al-Buruj, and the Prophet ﷺ told the full story, in Sahih Muslim (narrated by Suhayb). A king had a sorcerer, who, as he aged, was given a boy to train. On the way the boy met a monk and secretly learned the truth about Allah.',
      'The boy healed the blind and the sick, and said, "I do not heal; Allah heals." When the king found out he killed the monk and tried to kill the boy several times, but failed. The boy told the king how he could be killed: gather the people, take an arrow from my quiver, and say "In the name of Allah, the Lord of this boy." The king did so, and the boy died. The people shouted, "We believe in the Lord of the boy!"',
      'Furious, the king dug trenches and lit fires, throwing those who would not renounce their faith into them. When a woman with her baby hesitated, the baby spoke: "Be patient, mother, for you are on the truth."',
    ],
    l: ['Faith can spread through the courage of one young person.', 'The believers’ steadfastness is valued by Allah more than their survival.'],
    v: [[85, 4, 9]], src: 'Sahih Muslim (Suhayb); Qur’an 85:4–10',
  },
  {
    id: 'pharaoh-believer', shelf: 'quran', title: 'The Believer from Pharaoh’s Household', ar: 'مؤمن آل فرعون',
    p: [
      'When Fir’awn threatened to kill Musa, a man from his own household, who had hidden his faith, spoke out: "Would you kill a man because he says, My Lord is Allah, when he has brought you clear proofs from your Lord?"',
      'He warned them with the fate of earlier peoples, called them to the path of right guidance, and said: "I entrust my affair to Allah." Allah protected him from what they plotted, and Fir’awn’s people were struck by the worst punishment.',
    ],
    l: ['Speak the truth where you are, even in the most difficult setting.', 'Trusting Allah protects from harm in ways we cannot see.'],
    v: [[40, 28, 29], [40, 44, 45]], src: 'Qur’an 40:28–45',
  },
  {
    id: 'yasin-man', shelf: 'quran', title: 'The Man from the Edge of the City', ar: 'رجل من أقصى المدينة',
    p: [
      'Messengers came to a town and its people rejected them. A man came running from the far end of the city: "O my people, follow the messengers! Follow those who ask no payment and who are rightly guided."',
      'They killed him. Allah said to him, "Enter Paradise," and he said: "If only my people knew how my Lord has forgiven me and made me among the honoured." He is remembered for wishing them good even after what they did.',
    ],
    l: ['One person can speak up when others stay silent.', 'A believer’s heart stays kind even to those who harmed him.'],
    v: [[36, 20, 27]], src: 'Qur’an 36:13–32',
  },
  {
    id: 'talut-jalut', shelf: 'quran', title: 'Talut, Jalut and young Dawud', ar: 'طالوت وجالوت',
    p: [
      'Bani Israil asked their prophet for a king to lead them in battle. Allah appointed Talut. They objected that he lacked wealth, but the prophet said Allah gave him knowledge and strength in body. As the army set out, Talut tested them with a river: those who drank little were with him; those who drank much were not.',
      'When they faced Jalut’s great army, even the believers said, "We have no power today." But those who were sure they would meet Allah said, "How many a small group has overcome a large one by Allah’s permission!" Dawud killed Jalut, and Allah gave him kingship.',
    ],
    l: ['Victory comes from Allah, not numbers.', 'Obedience and discipline matter before the battle.'],
    v: [[2, 246, 251]], src: 'Qur’an 2:246–251',
  },
  {
    id: 'two-gardens', shelf: 'quran', title: 'The Man of the Two Gardens', ar: 'صاحب الجنتين',
    p: [
      'Two men: one had two gardens of grapevines and palms with a river running between, and boasted to his friend, "I am greater than you in wealth and mightier in manpower." He said he doubted the Hour would come.',
      'His friend, a believer, told him: "When you entered your garden, why did you not say, What Allah wills; there is no power except with Allah?" Soon the gardens were destroyed, and the man wrung his hands in regret over what he had spent on them.',
    ],
    l: ['Say "Masha Allah, la quwwata illa billah" when you see blessings.', 'What you own can be gone overnight; faith is the only wealth that stays.'],
    v: [[18, 32, 44]], src: 'Qur’an 18:32–44',
  },
);
