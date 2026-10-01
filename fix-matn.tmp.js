const fs = require('fs');
let b = fs.readFileSync('scripts/build-discover.js', 'utf8');
const start = b.indexOf('// The text is "chain of narrators');
const end = b.indexOf('const seen = new Set();');
if (start < 0 || end < 0) throw new Error('anchors');
const fn = String.raw`// The text is "chain of narrators, then the Prophet's words in quotation marks". Keep the quoted words, or, where an entry gives
// explicit "from" / "to" phrases, exactly the stretch between them (matched ignoring diacritics, cut from the original text).
function stripMap(s) {
  const map = [];
  let out = '';
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (/[ً-ٰٟۖ-ۭـ]/.test(ch)) continue;
    out += strip(ch);
    map.push(i);
  }
  return { out, map };
}
function matnOf(text, c) {
  if (c.from) {
    const { out, map } = stripMap(text);
    const a = out.indexOf(strip(c.from));
    if (a < 0) throw new Error(c.id + ': "from" phrase not found');
    const toKey = strip(c.to || c.from);
    const z = out.indexOf(toKey, a);
    if (z < 0) throw new Error(c.id + ': "to" phrase not found');
    return text.slice(map[a], map[z + toKey.length - 1] + 1).replace(/\s+/g, ' ').trim();
  }
  const m = text.match(/‏\s*"\s*‏\s*([\s\S]*?)\s*‏?\s*"\s*‏?/);
  return (m ? m[1] : text).replace(/[‎‏]/g, '').replace(/\s+/g, ' ').replace(/\s*\.\s*$/, '').trim();
}
`;
b = b.slice(0, start) + fn + b.slice(end);
b = b.replace('const matn = matnOf(raw);', 'const matn = matnOf(raw, c);');
fs.writeFileSync('scripts/build-discover.js', b);

let h = fs.readFileSync('scripts/hadith-curation.js', 'utf8');
const addRange = (id, from, to) => {
  const marker = `{ id: '${id}',`;
  if (!h.includes(marker)) throw new Error('missing id ' + id);
  h = h.replace(marker, `{ id: '${id}', from: '${from}', to: '${to}',`);
};
addRange('safe-tongue', 'المسلم من سلم المسلمون', 'ما نهى الله عنه');
addRange('best-character', 'إن من أكمل المؤمنين', 'والطفهم باهله');
addRange('smile', 'تبسمك في وجه أخيك', 'في دلو أخيك لك صدقة');
addRange('friend-religion', 'الرجل على دين خليله', 'من يخالل');
addRange('the-merciful', 'الراحمون يرحمهم', 'ومن قطعها قطعه الله');
addRange('no-mercy', 'من لا يرحم لا يرحم', 'من لا يرحم لا يرحم');
addRange('young-and-old', 'ليس منا من لم يرحم صغيرنا', 'ويوقر كبيرنا');
addRange('best-of-sinners', 'كل ابن آدم خطاء', 'التوابون');
addRange('dua-is-worship', 'الدعاء هو العبادة', 'الدعاء هو العبادة');
addRange('best-learn-quran', 'خيركم من تعلم القرآن', 'وعلمه');
addRange('path-of-knowledge', 'من نفس عن مؤمن', 'لم يسرع به نسبه');
addRange('upper-hand', 'أفضل الصدقة ما ترك غنى', 'وابدأ بمن تعول');
addRange('atom-of-pride', 'لا يدخل الجنة من كان في قلبه', 'وغمط الناس');
addRange('la-ilaha-100', 'من قال لا إله إلا الله وحده', 'مثل زبد البحر');
addRange('my-servants-thought', 'أنا عند ظن عبدي بي', 'أتيته هرولة');
addRange('modesty', 'دعه فإن الحياء من الإيمان', 'دعه فإن الحياء من الإيمان');
// English that has to cover what the Arabic now contains in full
const fixEn = (a, b) => { if (!h.includes(a)) throw new Error('en missing ' + a.slice(0, 40)); h = h.replace(a, b); };
fixEn("en: 'No one will enter Paradise who has in his heart the weight of an atom of pride.'", "en: 'No one will enter Paradise who has in his heart the weight of an atom of pride. A man said: a person likes his clothes and his shoes to be good. The Prophet \\uFDFA said: Allah is Beautiful and loves beauty. Pride is rejecting the truth and looking down on people.'");
fixEn("and it is a protection from Satan for that day until evening.'", "and it is a protection from Satan for that day until evening. No one will have done better than that, except someone who did more. And whoever says \"Subhan Allahi wa bihamdihi\" a hundred times in a day, his sins are wiped away even if they are like the foam of the sea.'");
fixEn("en: 'The Prophet \\uFDFA passed by a man advising his brother about being too shy, and said: leave him, for modesty is part of faith.'", "en: 'The Prophet \\uFDFA passed by a man who was scolding his brother for being shy, and said: \"Leave him, for modesty is part of faith.\"'");
fs.writeFileSync('scripts/hadith-curation.js', h);
console.log('matn extraction fixed');
