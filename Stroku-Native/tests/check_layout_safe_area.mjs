import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const projectRoot = process.cwd();
const designSize = { width: 1920, height: 1080 };
const visibleAreaByResolution = [
    { name: 'HD 720p with 5% overscan', width: 1280, height: 720, insetRatio: 0.05 },
    { name: 'WXGA 768p with 5% overscan', width: 1366, height: 768, insetRatio: 0.05 },
    { name: 'FHD 1080p with 5% overscan', width: 1920, height: 1080, insetRatio: 0.05 },
    { name: 'FHD 1080p exact viewport', width: 1920, height: 1080, insetRatio: 0 },
];

const xmlChecks = [
    {
        file: 'components/MainScene.xml',
        nodes: [
            { id: 'searchBar', label: 'home search bar', requireViewportBounds: true },
            { id: 'searchPrompt', label: 'home search text', requireViewportBounds: true },
            { id: 'setupAddress', label: 'setup address', requireViewportBounds: true },
            { id: 'primaryTitle', label: 'home title', requireFullSafeArea: true },
            { id: 'primarySubtitle', label: 'home subtitle', requireViewportBounds: true },
            { id: 'discoverGrid', label: 'discover grid', requireViewportBounds: true },
            // Calendar screen. The list panel, the detail panel and everything
            // drawn inside them has to survive a 5% overscan, because the
            // detail column sits hard against the right design edge.
            { id: 'calendarListPanel', label: 'calendar list panel', requireFullSafeArea: true },
            { id: 'calendarList', label: 'calendar list', requireFullSafeArea: true },
            { id: 'calendarDetailPanel', label: 'calendar detail panel', requireFullSafeArea: true },
            { id: 'calendarDetailPoster', label: 'calendar detail poster', requireFullSafeArea: true },
            { id: 'calendarDetailTitle', label: 'calendar detail title', requireFullSafeArea: true },
            { id: 'calendarDetailDescription', label: 'calendar detail description', requireFullSafeArea: true },
            { id: 'calendarDetailActionPill', label: 'calendar detail action pill', requireFullSafeArea: true },
            // Addons screen. The toolbar chips run to the right design edge and
            // the last one is the first thing an overscanning TV clips.
            { id: 'addonChip0Bg', label: 'addons first chip', requireFullSafeArea: true },
            { id: 'addonChip2Bg', label: 'addons add-addon chip', requireFullSafeArea: true },
            { id: 'addonChip4Bg', label: 'addons last chip', requireFullSafeArea: true },
            { id: 'addonChip4Label', label: 'addons last chip label', requireFullSafeArea: true },
            { id: 'addonsListPanel', label: 'addons list panel', requireFullSafeArea: true },
            { id: 'addonList', label: 'addons list', requireFullSafeArea: true },
            { id: 'addonsDetailPanel', label: 'addons detail panel', requireFullSafeArea: true },
            { id: 'addonDetailTitle', label: 'addons detail title', requireFullSafeArea: true },
            { id: 'addonDetailHint', label: 'addons detail hint', requireFullSafeArea: true },
            { id: 'addonDetailSource', label: 'addons detail source', requireFullSafeArea: true },
            { id: 'addonDetailActionPill', label: 'addons detail action pill', requireFullSafeArea: true },
            { id: 'settingsTab0Bg', label: 'settings first tab', requireFullSafeArea: true },
            { id: 'settingsTab2Bg', label: 'settings last tab', requireFullSafeArea: true },
            { id: 'settingsTab2Label', label: 'settings last tab label', requireFullSafeArea: true },
            { id: 'settingsTabIndicator', label: 'settings tab indicator', requireFullSafeArea: true },
            { id: 'settingsListPanel', label: 'settings list panel', requireFullSafeArea: true },
            { id: 'settingsList', label: 'settings list', requireFullSafeArea: true },
            { id: 'settingsDetailPanel', label: 'settings detail panel', requireFullSafeArea: true },
            { id: 'settingsDetailTitle', label: 'settings detail title', requireFullSafeArea: true },
            { id: 'settingsDetailHint', label: 'settings detail hint', requireFullSafeArea: true },
            { id: 'heroTitle', label: 'home footer title', requireViewportBounds: true },
            { id: 'heroDescription', label: 'home footer description', requireViewportBounds: true },
            { id: 'noStreamsPoster', label: 'no-streams poster', requireViewportBounds: true },
            { id: 'noStreamsMessage', label: 'no-streams message', requireFullSafeArea: true },
            { id: 'noStreamsHint', label: 'no-streams action button', requireFullSafeArea: true },
            { id: 'seasonGrid', label: 'season tabs', requireViewportBounds: true },
            { id: 'episodeList', label: 'episode list', requireViewportBounds: true },
            { id: 'choiceTitle', label: 'stream picker title', requireFullSafeArea: true },
            { id: 'choiceList', label: 'choice list', requireViewportBounds: true },
            { id: 'streamList', label: 'stream list', requireViewportBounds: true },
            { id: 'statusBackdrop', label: 'status dialog', requireViewportBounds: true },
            { id: 'statusLabel', label: 'status text', requireFullSafeArea: true },
            { id: 'uiScaleMessage', label: 'ui scale message', requireFullSafeArea: true },
            { id: 'uiScaleTrack', label: 'ui scale track', requireFullSafeArea: true },
            // The fill never exceeds the track, which is checked above.
            { id: 'uiScaleFill', label: 'ui scale fill', requireFullSafeArea: true },
            { id: 'uiScaleHandle', label: 'ui scale handle', requireFullSafeArea: true },
            { id: 'uiScaleValue', label: 'ui scale value', requireFullSafeArea: true },
            // Support panel. The QR has to survive overscan intact or it stops
            // scanning, so every part of it is held to the full safe area.
            { id: 'coffeeQrPlate', label: 'support qr plate', requireFullSafeArea: true },
            { id: 'coffeeQr', label: 'support qr code', requireFullSafeArea: true },
            { id: 'coffeeScanHint', label: 'support scan hint', requireFullSafeArea: true },
            { id: 'coffeeUrl', label: 'support url', requireFullSafeArea: true },
            { id: 'coffeeDismissHint', label: 'support dismiss hint', requireFullSafeArea: true },
            // Top bar support entry. Held to the viewport rather than the safe
            // area because it shares the search bar's row, and that row already
            // sits above the 5% inset by design.
            { id: 'supportChipBg', label: 'top bar support chip', requireViewportBounds: true },
            { id: 'supportChipLabel', label: 'top bar support chip label', requireViewportBounds: true },
        ],
    },
    {
        file: 'components/StrokuVideoPlayer.xml',
        nodes: [
            { id: 'customSubtitleBackdrop', label: 'custom subtitle backdrop', requireViewportBounds: true },
            { id: 'customSubtitleLabel', label: 'custom subtitle label', requireViewportBounds: true },
            { id: 'titleLabel', label: 'playback title', requireViewportBounds: true },
            { id: 'timeLabel', label: 'playback time', requireViewportBounds: true },
            { id: 'progressBg', label: 'playback progress background', requireViewportBounds: true },
            { id: 'progressFill', label: 'playback progress', requireViewportBounds: true },
            { id: 'playButton', label: 'play button', requireViewportBounds: true },
            { id: 'audioButton', label: 'audio button', requireViewportBounds: true },
            { id: 'subtitleButton', label: 'subtitle button', requireViewportBounds: true },
            { id: 'speedButton', label: 'speed button', requireViewportBounds: true },
            { id: 'nextButton', label: 'next episode button', requireViewportBounds: true },
            { id: 'scrubTooltip', label: 'scrub tooltip', requireViewportBounds: true },
            { id: 'scrubCursor', label: 'scrub cursor', requireViewportBounds: true },
            { id: 'speedList', label: 'speed menu list', requireFullSafeArea: true },
            { id: 'audioList', label: 'audio menu list', requireFullSafeArea: true },
            { id: 'subtitleSyncLabel', label: 'subtitle sync label', requireFullSafeArea: true },
            { id: 'subtitleList', label: 'subtitle menu list', requireFullSafeArea: true },
        ],
    },
];

const brightScriptChecks = [
    {
        file: 'components/StrokuVideoPlayer.brs',
        label: 'playback focus translations',
        match: /m\.buttonTranslations\s*=\s*\[(?<translations>[\s\S]*?)\]\s*\r?\n\s*m\.buttonSizes/,
        size: { width: 80, height: 80 },
        requireViewportBounds: true,
    },
];

const failures = [];

for (const check of xmlChecks) {
    const filePath = path.join(projectRoot, check.file);
    const xml = fs.readFileSync(filePath, 'utf8');
    const parsedNodes = parseXmlNodes(xml);

    for (const expected of check.nodes) {
        const node = parsedNodes.get(expected.id);
        if (!node) {
            failures.push(`${check.file}: missing node id="${expected.id}" (${expected.label})`);
            continue;
        }

        validateBox({
            file: check.file,
            label: expected.label,
            source: `id="${expected.id}"`,
            box: node,
            requireFullSafeArea: expected.requireFullSafeArea,
            requireViewportBounds: expected.requireViewportBounds,
        });
    }
}

for (const check of brightScriptChecks) {
    const filePath = path.join(projectRoot, check.file);
    const source = fs.readFileSync(filePath, 'utf8');
    const match = source.match(check.match);
    if (!match?.groups?.translations) {
        failures.push(`${check.file}: missing ${check.label}`);
        continue;
    }

    for (const [index, translation] of parseBrightScriptTranslations(match.groups.translations).entries()) {
        validateBox({
            file: check.file,
            label: `${check.label} ${index}`,
            source: translation.source,
            box: { ...translation, ...check.size },
            requireFullSafeArea: check.requireFullSafeArea,
            requireViewportBounds: check.requireViewportBounds,
        });
    }
}

if (failures.length > 0) {
    console.error('Layout safe-area validation failed:');
    for (const failure of failures) {
        console.error(`- ${failure}`);
    }
    process.exit(1);
}

console.log(`Layout safe-area validation passed for ${visibleAreaByResolution.length} screen profiles.`);

function parseXmlNodes(xml) {
    const nodes = new Map();
    const elementPattern = /<(?<tag>[A-Za-z][\w.]*)\b(?<attrs>[^>]*?)\/?>/gms;
    let match;

    while ((match = elementPattern.exec(xml)) !== null) {
        const attrs = parseAttributes(match.groups.attrs);
        if (!attrs.id || !attrs.translation || !attrs.width || !attrs.height) continue;

        const translation = parsePair(attrs.translation);
        const width = Number(attrs.width);
        const height = Number(attrs.height);
        if (!translation || !Number.isFinite(width) || !Number.isFinite(height)) continue;

        nodes.set(attrs.id, {
            x: translation[0],
            y: translation[1],
            width,
            height,
        });
    }

    return nodes;
}

function parseAttributes(attrs) {
    const result = {};
    const attrPattern = /(?<name>[\w.:-]+)\s*=\s*"(?<value>[^"]*)"/g;
    let match;

    while ((match = attrPattern.exec(attrs)) !== null) {
        result[match.groups.name] = match.groups.value;
    }

    return result;
}

function parsePair(value) {
    const match = value.match(/^\[\s*(?<x>-?\d+(?:\.\d+)?)\s*,\s*(?<y>-?\d+(?:\.\d+)?)\s*\]$/);
    if (!match) return undefined;
    return [Number(match.groups.x), Number(match.groups.y)];
}

function parseBrightScriptTranslations(source) {
    const translations = [];
    const pairPattern = /\[\s*(?<x>-?\d+(?:\.\d+)?)\s*,\s*(?<y>-?\d+(?:\.\d+)?)\s*\]/g;
    let match;

    while ((match = pairPattern.exec(source)) !== null) {
        translations.push({
            x: Number(match.groups.x),
            y: Number(match.groups.y),
            source: match[0],
        });
    }

    return translations;
}

function validateBox({ file, label, source, box, requireFullSafeArea = false, requireViewportBounds = false }) {
    for (const profile of visibleAreaByResolution) {
        const scaled = scaleBox(box, profile);
        const viewport = {
            left: 0,
            top: 0,
            right: profile.width,
            bottom: profile.height,
        };
        const safeArea = {
            left: profile.width * profile.insetRatio,
            top: profile.height * profile.insetRatio,
            right: profile.width * (1 - profile.insetRatio),
            bottom: profile.height * (1 - profile.insetRatio),
        };

        if (requireViewportBounds && !isInside(scaled, viewport)) {
            failures.push(formatFailure(file, label, source, profile, scaled, viewport, 'viewport'));
        }

        if (requireFullSafeArea && !isInside(scaled, safeArea)) {
            failures.push(formatFailure(file, label, source, profile, scaled, safeArea, 'safe area'));
        }
    }
}

function scaleBox(box, profile) {
    const scaleX = profile.width / designSize.width;
    const scaleY = profile.height / designSize.height;
    return {
        left: box.x * scaleX,
        top: box.y * scaleY,
        right: (box.x + box.width) * scaleX,
        bottom: (box.y + box.height) * scaleY,
    };
}

function isInside(box, bounds) {
    return box.left >= bounds.left
        && box.top >= bounds.top
        && box.right <= bounds.right
        && box.bottom <= bounds.bottom;
}

function formatFailure(file, label, source, profile, box, bounds, boundsLabel) {
    return `${file}: ${label} (${source}) is outside ${profile.name} ${boundsLabel}. `
        + `box=${formatBox(box)} allowed=${formatBox(bounds)}`;
}

function formatBox(box) {
    return `[${round(box.left)}, ${round(box.top)}]-[${round(box.right)}, ${round(box.bottom)}]`;
}

function round(value) {
    return Math.round(value * 10) / 10;
}
