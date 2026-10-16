'use strict';
// Merges the story modules in scripts/stories/*.js into iqra_app/assets/data/content.json:
//   node scripts/build-content.js
//
// A module exports { shelves?, stories?, extend? }:
//   shelves: [{ id, title, ar, blurb }]                      new shelves (skipped if the id exists)
//   stories: [{ shelf, id, title, ar, era?, ord?, p, l, v, src, facts?, s }]
//            facts: [[label, value]], s: [{ h, t: [paragraph…] }]  (the in-depth part)
//   extend:  { storyId: { facts?: [[label, value]], s: [{ h, t }] } }   chapters appended to an existing story
//   occasions: [{ m, d, name, note, story? }]                      Hijri-calendar events (merged by name; story = id to open)
//   remove:  [storyId]                                                 stories to delete (with their chapters)
// The merge is idempotent: a story id that already exists is replaced, and an extension chapter is added only once.
const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, '..', 'iqra_app', 'assets', 'data', 'content.json');
const content = JSON.parse(fs.readFileSync(file, 'utf8'));
const d = content.discover;
d.deep = d.deep || {};

const dir = path.join(__dirname, 'stories');
const modules = fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith('.js')).sort() : [];
let added = 0, replaced = 0, chapters = 0;

const words = (s) => s.split(/\s+/).filter(Boolean).length;
const problems = [];

for (const m of modules) {
  const mod = require(path.join(dir, m));
  for (const id of mod.remove || []) {
    const j = d.stories.findIndex((x) => x.id === id);
    if (j >= 0) { d.stories.splice(j, 1); delete d.deep[id]; }
  }
  for (const o of mod.occasions || []) {
    const j = d.occasions.findIndex((x) => x.name === o.name);
    if (j >= 0) d.occasions[j] = { ...d.occasions[j], ...o }; else d.occasions.push(o);
  }
  for (const sh of mod.shelves || []) {
    if (!d.shelves.some((x) => x.id === sh.id)) d.shelves.push(sh);
  }
  for (const st of mod.stories || []) {
    const { facts, s, ...story } = st;
    if (!story.id || !story.title || !Array.isArray(story.p) || !story.p.length) problems.push(`${m}: story without id/title/p: ${story.id}`);
    if (!d.shelves.some((x) => x.id === story.shelf)) problems.push(`${m}: ${story.id} has unknown shelf ${story.shelf}`);
    const i = d.stories.findIndex((x) => x.id === story.id);
    if (i >= 0) { d.stories[i] = story; replaced++; } else { d.stories.push(story); added++; }
    if (s && s.length) d.deep[story.id] = { facts: facts || [], s };
  }
  for (const [id, ext] of Object.entries(mod.extend || {})) {
    if (!d.stories.some((x) => x.id === id)) { problems.push(`${m}: extend of unknown story ${id}`); continue; }
    const deep = (d.deep[id] ||= { facts: [], s: [] });
    for (const f of ext.facts || []) if (!deep.facts.some((x) => x[0] === f[0])) deep.facts.push(f);
    for (const sec of ext.s || []) {
      if (!deep.s.some((x) => x.h === sec.h)) { deep.s.push(sec); chapters++; }
    }
  }
}

if (problems.length) {
  console.error(problems.join('\n'));
  process.exit(1);
}

d.occasions.sort((a, b) => a.m - b.m || a.d - b.d);
// summary
const total = d.stories.map((st) => {
  const dp = d.deep[st.id];
  return words(st.p.join(' ')) + (dp ? dp.s.reduce((n, x) => n + x.t.reduce((a, t) => a + words(t), 0), 0) : 0);
});
fs.writeFileSync(file, JSON.stringify(content));
console.log(`stories: ${d.stories.length} (+${added} new, ${replaced} replaced), ${chapters} chapters added`);
console.log(`words: ${total.reduce((a, b) => a + b, 0)} in total, average ${Math.round(total.reduce((a, b) => a + b, 0) / total.length)} per story, longest ${Math.max(...total)}`);
