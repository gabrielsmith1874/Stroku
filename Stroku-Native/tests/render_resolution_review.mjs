import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { chromium } from 'playwright';

const projectRoot = process.cwd();
const inputDir = path.join(projectRoot, 'screenshots', 'resolution-check');
const outputDir = path.join(inputDir, 'review');

const profiles = [
    { name: 'hd-1280x720', label: 'HD 1280x720', width: 1280, height: 720 },
    { name: 'wxga-1366x768', label: 'WXGA 1366x768', width: 1366, height: 768 },
    { name: 'fhd-1920x1080', label: 'FHD 1920x1080', width: 1920, height: 1080 },
];

const screens = [
    { id: '01-home', label: 'Home' },
    { id: '02-details', label: 'Details' },
    { id: '03-streams', label: 'Stream Picker' },
];

fs.mkdirSync(outputDir, { recursive: true });

const browser = await chromium.launch({ headless: true });
try {
    for (const profile of profiles) {
        for (const screen of screens) {
            await renderReviewImage(browser, profile, screen);
        }
    }
} finally {
    await browser.close();
}

console.log(`Resolution review images saved to ${outputDir}`);

async function renderReviewImage(browser, profile, screen) {
    const inputPath = path.join(inputDir, `${profile.name}-${screen.id}.png`);
    if (!fs.existsSync(inputPath)) {
        throw new Error(`Missing input screenshot: ${inputPath}`);
    }

    const page = await browser.newPage({ viewport: { width: profile.width, height: profile.height } });
    try {
        const dataUrl = `data:image/png;base64,${fs.readFileSync(inputPath).toString('base64')}`;
        await page.setContent(`
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>
                        html, body {
                            width: 100%;
                            height: 100%;
                            margin: 0;
                            overflow: hidden;
                            background: #05050b;
                            font-family: Arial, sans-serif;
                        }
                        img {
                            position: absolute;
                            inset: 0;
                            width: 100%;
                            height: 100%;
                        }
                        .safe {
                            position: absolute;
                            left: 5%;
                            top: 5%;
                            right: 5%;
                            bottom: 5%;
                            border: max(3px, 0.25vw) solid #33ff99;
                            box-sizing: border-box;
                            pointer-events: none;
                        }
                        .label {
                            position: absolute;
                            left: 16px;
                            top: 14px;
                            padding: 8px 12px;
                            border-radius: 4px;
                            background: rgba(0, 0, 0, 0.72);
                            color: #fff;
                            font-size: 18px;
                            line-height: 1.25;
                        }
                    </style>
                </head>
                <body>
                    <img src="${dataUrl}" alt="">
                    <div class="safe"></div>
                    <div class="label">${profile.label} - ${screen.label}<br>green rectangle = 5% overscan-safe area</div>
                </body>
            </html>
        `);
        await page.screenshot({
            path: path.join(outputDir, `${profile.name}-${screen.id}-safe-area.png`),
            fullPage: false,
        });
    } finally {
        await page.close();
    }
}
