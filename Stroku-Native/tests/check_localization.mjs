import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// Guards the localization layer against the two ways it rots quietly:
// a key added to English only, and a screen that goes back to hardcoded English
// while UI Language still claims to switch it.

const root = process.cwd();
const locale = fs.readFileSync(path.join(root, 'components/Locale.brs'), 'utf8');
const mainScene = fs.readFileSync(path.join(root, 'components/MainScene.brs'), 'utf8');

const failures = [];

const tables = {};
for (const match of locale.matchAll(/function LocaleStrings(\w+)\(\) as object([\s\S]*?)\nend function/g)) {
    const entries = new Map();
    for (const entry of match[2].matchAll(/^\s*"([^"]+)":\s*"([^"]*)"/gm)) {
        entries.set(entry[1], entry[2]);
    }
    tables[match[1]] = entries;
}

const expectedLanguages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese'];
for (const language of expectedLanguages) {
    if (!tables[language]) failures.push(`Locale.brs has no string table for ${language}`);
}

const english = tables.English;
if (!english || english.size === 0) {
    failures.push('Locale.brs English table is missing or empty');
} else {
    for (const language of expectedLanguages) {
        const table = tables[language];
        if (!table) continue;

        for (const key of english.keys()) {
            if (!table.has(key)) failures.push(`${language} is missing key ${key}`);
        }
        for (const key of table.keys()) {
            if (!english.has(key)) failures.push(`${language} has key ${key} that English does not`);
        }
        for (const [key, value] of table) {
            if (value.trim() === '') failures.push(`${language} has an empty string for ${key}`);
        }
    }
}

// Every literal key looked up in app code must exist, or the UI silently renders
// the key itself.
for (const match of mainScene.matchAll(/\bTrText\("([^"]+)"\)/g)) {
    if (english && !english.has(match[1])) {
        failures.push(`MainScene.brs looks up missing key ${match[1]}`);
    }
}

// TrOption composes prefix + slug at runtime, so assert the prefix has entries.
for (const match of mainScene.matchAll(/TrOption\("([^"]+)"/g)) {
    const prefix = `${match[1]}.`;
    const hasAny = english && [...english.keys()].some((key) => key.startsWith(prefix));
    if (!hasAny) failures.push(`MainScene.brs uses TrOption prefix ${match[1]} with no matching keys`);
}

// The mechanism has to stay wired: these are the surfaces UI Language claims to
// change, and a regression to English literals here would be invisible.
const wiringChecks = [
    ['Locale.brs registered in the scene', /Locale\.brs/, fs.readFileSync(path.join(root, 'components/MainScene.xml'), 'utf8')],
    ['Stored language applied on startup', /SetLocaleLanguage\(m\.interfaceLanguage\)/, mainScene],
    ['Language change republishes and re-renders nav', /SetLocaleLanguage\(m\.interfaceLanguage\)\s*\n\s*UpdateNavContent\(\)/, mainScene],
    ['Nav labels route through TrText', /child\.title = TrText\("nav\." \+ id\)/, mainScene],
    ['Nav identity kept separate from nav labels', /m\.navIds = \[/, mainScene],
    ['Settings tab chips route through TrText', /label\.text = TrText\("settings\.tab\./, mainScene],
];

for (const [label, pattern, source] of wiringChecks) {
    if (!pattern.test(source)) failures.push(`${label} is missing`);
}

// Tab ids must never be derived from translated labels again.
if (/LCase\(m\.navItems\[/.test(mainScene)) {
    failures.push('MainScene.brs derives a tab id from a translated nav label');
}

if (failures.length > 0) {
    console.error('Localization checks failed:');
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
}

const keyCount = english ? english.size : 0;
console.log(`Localization checks passed (${keyCount} keys x ${expectedLanguages.length} languages).`);
