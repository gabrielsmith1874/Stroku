import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = process.cwd();
const mainScene = fs.readFileSync(path.join(root, 'components/MainScene.brs'), 'utf8');
const videoPlayer = fs.readFileSync(path.join(root, 'components/StrokuVideoPlayer.brs'), 'utf8');
const videoXml = fs.readFileSync(path.join(root, 'components/StrokuVideoPlayer.xml'), 'utf8');
const episodeCard = fs.readFileSync(path.join(root, 'components/EpisodeCard.brs'), 'utf8');
const episodeXml = fs.readFileSync(path.join(root, 'components/EpisodeCard.xml'), 'utf8');
const locale = fs.readFileSync(path.join(root, 'components/Locale.brs'), 'utf8');

// The search dialog copy now lives in the localization layer, so the
// "does not overpromise TVDB" guarantee is asserted against the English table
// rather than against a literal in MainScene.brs.
const englishTable = (locale.match(/function LocaleStringsEnglish\(\) as object([\s\S]*?)\nend function/) || [])[1] || '';

const failures = [];

const requiredMainPatterns = [
    ['Addons Installed filter action', /AddonChip\(TrText\("addons\.filter\.installed"\),\s*"addonFilterInstalled"/],
    ['Addons All filter action', /AddonChip\(TrText\("addons\.filter\.all"\),\s*"addonFilterAll"/],
    ['Remote Stremio add-on collection request', /https:\/\/api\.strem\.io\/addonscollection\.json/],
    ['Remote add-on details handler', /sub ShowAddonDetails\(addon as object\)/],
    ['Installed add-on details handler', /sub ShowInstalledAddonDetails\(index as integer\)/],
    ['Settings links handler', /sub OpenSettingsLink\(kind as string\)/],
    ['Settings rows carry a value, kind, and hint', /function SettingRow\(title as string, value as string, actionType as string, payload as dynamic, kind as string, hint as string\)/],
    ['Settings sections are headers rather than list rows', /function SettingHeader\(title as string\)/],
    ['Settings headers are skipped when moving focus', /function NextSelectableSettingsIndex\(/],
    ['Settings detail panel follows the focused row', /sub UpdateSettingsDetail\(index as integer\)/],
    ['Settings headers are skipped when moving focus', /function NextSelectableSettingsIndex\(/],
    ['Settings detail panel follows the focused row', /sub UpdateSettingsDetail\(index as integer\)/],
    ['Settings remote movement skips headers before list focus changes', /function FocusSettingsSelectableRow\(direction as integer\) as boolean[\s\S]*?m\.settingsSuppressIndex = target[\s\S]*?m\.settingsList\.animateToItem = target[\s\S]*?UpdateSettingsDetail\(target\)[\s\S]*?return true/],
    ['Settings up/down keys use selectable row movement', /else if \(key = "up" or key = "down"\) and m\.activeTab = "settings" and m\.settingsList\.HasFocus\(\)[\s\S]*?return FocusSettingsSelectableRow\(direction\)/],
    ['Interface preference persistence', /sub SaveInterfacePreferences\(\)/],
    ['Player preference persistence', /sub SavePlayerPreferences\(\)/],
    ['Blur unwatched episodes writes card field', /blurThumbnail: true/],
    ['App version comes from the device rather than a literal', /SettingRow\(TrText\("settings\.general\.appVersion"\),\s*AppVersionValue\(\)/],
    ['App version reads roAppInfo', /function AppVersionValue\(\) as string[\s\S]*?CreateObject\("roAppInfo"\)/],
    ['Channel build reads roAppInfo', /function AppBuildValue\(\) as string[\s\S]*?CreateObject\("roAppInfo"\)/],
    ['Reload add-ons survives on the Addons screen', /AddonChip\(TrText\("addons\.reload"\),\s*"reloadAddons"/],
    ['Calendar metadata request', /"calendarMeta\|"/],
    ['Calendar entries render dated episodes', /function CalendarEntryTitle\(entry as object\) as string/],
    ['Calendar loading row is inert', /CalendarMessageRow\(TrText\("calendar\.loading"\)\)/],
    ['Calendar upcoming header is inert', /CalendarHeaderRow\(TrText\("calendar\.section\.upcoming"\)\)/],
    ['Calendar recent header is inert', /CalendarHeaderRow\(TrText\("calendar\.section\.recent"\)\)/],
    ['Calendar message rows are inert by construction', /function CalendarMessageRow\(title as string\) as object\s*\n\s*return CalendarRow\("message", title, "none"/],
    ['Calendar header rows are inert by construction', /function CalendarHeaderRow\(title as string\) as object\s*\n\s*return CalendarRow\("header", title, "none"/],
    // The calendar is a card list now, not an info list. This used to match
    // RenderInfoList, which the calendar no longer goes through, so it passed
    // without proving anything about the calendar.
    ['Calendar refresh preserves focused control', /else if not focusContent\s+targetIndex = m\.calendarFocusIndex/],
    ['Calendar chips and cards do not both own the Addons screen', /sub DispatchAddonAction\(actionType as string, payload as dynamic\)/],
    ['Addons toolbar is reachable from the card list', /FocusAddonChips\(\)\s*\n\s*return true/],
    ['Addons toolbar hands OK to the chip it is on', /ActivateAddonChip\(m\.addonChipIndex\)/],
    ['Calendar metadata requests are capped', /CountCalendarTrackedSeries\(\) >= 24/],
    ['Calendar metadata concurrency is capped', /pending >= 4/],
    ['Calendar entries are trimmed', /sub TrimCalendarEntries\(\)/],
    ['Calendar full sort removed from action build', /AddSortedCalendarEntry\(upcoming,\s*entry,\s*true,\s*12\)/],
    ['Channel search request', /v3-channels\.strem\.io\/catalog\/channel\/top\/search=/],
    ['IMDb ID resolver', /function IsImdbId\(value as string\) as boolean/],
    ['Search dialog copy routes through the localization layer', /dialog\.message = TrText\("dialog\.search\.message"\)/],
];

const requiredLocalePatterns = [
    ['Search copy does not overpromise TVDB', /"dialog\.search\.message":\s*"Search movies, series, and channels/],
];

const forbiddenMainPatterns = [
    ['Installed filter reverted to no-op', /InfoAction\("Installed",\s*"none"/],
    ['All filter reverted to no-op', /InfoAction\("All",\s*"none"/],
    ['General settings links reverted to no-op', /SettingRow\("(Contact support|Source code|Terms of Service|Privacy Policy)",\s*[^,]+,\s*"none"/],
    ['Interface settings reverted to static rows', /SettingRow\("UI language",\s*[^,]+,\s*"none"/],
    ['Player defaults reverted to static rows', /SettingRow\("Default (language|audio track)",\s*[^,]+,\s*"none"/],
    ['Search dialog still advertises unsupported TVDB', /IMDB\/TVDB IDs/],
    ['App version hardcoded to a Stremio-mimicking literal', /appVersion"\),\s*"/],
    ['Streaming settings tab reintroduced', /"General",\s*"Interface",\s*"Player",\s*"Streaming"/],
];

const requiredVideoPatterns = [
    ['Default subtitle field exposed', /field id="defaultSubtitleLanguage"/],
    ['Default audio field exposed', /field id="defaultAudioTrack"/],
    ['Default subtitle chooser implemented', /function DefaultSubtitleIndex\(\) as integer/],
    ['Default audio chooser implemented', /sub ApplyDefaultAudioTrack\(\)/],
];

const requiredEpisodePatterns = [
    ['Unwatched thumbnail overlay node exposed', /id="thumbnailScrim"/],
    ['Unwatched thumbnail overlay driven by content field', /content\.DoesExist\("blurThumbnail"\) and content\.blurThumbnail/],
];

for (const [label, pattern] of requiredMainPatterns) {
    if (!pattern.test(mainScene)) failures.push(`${label} is missing from MainScene.brs`);
}

for (const [label, pattern] of forbiddenMainPatterns) {
    if (pattern.test(mainScene)) failures.push(`${label} in MainScene.brs`);
}

for (const [label, pattern] of requiredLocalePatterns) {
    if (!pattern.test(englishTable)) failures.push(`${label} is missing from the English table in Locale.brs`);
}

// The copy moved into Locale.brs, so the TVDB overpromise has to stay banned in
// every string table, not just in MainScene.brs.
if (/IMDB\/TVDB IDs/.test(locale)) {
    failures.push('Search dialog still advertises unsupported TVDB in Locale.brs');
}

for (const [label, pattern] of requiredVideoPatterns) {
    const source = label.includes('field') ? videoXml : `${videoXml}\n${videoPlayer}`;
    if (!pattern.test(source)) failures.push(`${label} is missing from video player implementation`);
}

for (const [label, pattern] of requiredEpisodePatterns) {
    if (!pattern.test(`${episodeXml}\n${episodeCard}`)) failures.push(`${label} is missing from episode card implementation`);
}

if (failures.length > 0) {
    console.error('Placeholder implementation checks failed:');
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
}

console.log('Placeholder implementation checks passed.');
