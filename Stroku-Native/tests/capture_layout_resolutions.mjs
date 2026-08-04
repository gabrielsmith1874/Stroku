import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { chromium } from 'playwright';

const projectRoot = process.cwd();
const toolsRoot = path.resolve(projectRoot, '..', 'tools', 'brs-engine');
const outputDir = path.join(projectRoot, 'screenshots', 'resolution-check');
const appSlot = path.join(toolsRoot, 'packages', 'browser', 'apps', 'stroku-native.zip');
const mockZip = path.join(projectRoot, 'dist', 'stroku-native-mock.zip');

const profiles = [
    { name: 'hd-1280x720', width: 1280, height: 720 },
    { name: 'wxga-1366x768', width: 1366, height: 768 },
    { name: 'fhd-1920x1080', width: 1920, height: 1080 },
];

fs.mkdirSync(outputDir, { recursive: true });

run().catch((error) => {
    console.error(error);
    process.exit(1);
});

async function run() {
    buildAndInstallMockApp();

    const mockServer = startProcess('node', ['tests/mock-addon-server.mjs'], {
        cwd: projectRoot,
        env: { ...process.env, STROKU_MOCK_PORT: '7319' },
    });
    const devServer = startProcess('npm.cmd', ['run', 'start', '-w', 'brs-engine'], {
        cwd: toolsRoot,
        shell: true,
    });

    try {
        await sleep(8000);
        const browser = await chromium.launch({ headless: true });
        try {
            for (const profile of profiles) {
                await captureProfile(browser, profile);
            }
        } finally {
            await browser.close();
        }
    } finally {
        stopProcess(mockServer);
        stopProcess(devServer);
    }

    console.log(`Screenshots saved to ${outputDir}`);
}

function buildAndInstallMockApp() {
    const result = spawnSync('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        'tests/build-mock-package.ps1',
    ], {
        cwd: projectRoot,
        encoding: 'utf8',
        stdio: 'pipe',
    });

    if (result.status !== 0) {
        throw new Error(`Mock package build failed:\n${result.stdout}\n${result.stderr}`);
    }

    fs.copyFileSync(mockZip, appSlot);
}

async function captureProfile(browser, profile) {
    console.log(`Capturing ${profile.name}...`);
    const page = await browser.newPage({ viewport: { width: profile.width, height: profile.height } });
    page.on('pageerror', (error) => console.error(`[${profile.name}] page error:`, error.message));

    try {
        await page.goto('http://127.0.0.1:6502', { waitUntil: 'load' });
        await page.waitForSelector('#app04', { timeout: 30000 });
        await page.click('#app04');
        await sleep(9000);

        const display = page.locator('#display');
        await display.screenshot({ path: path.join(outputDir, `${profile.name}-01-home.png`) });

        await pressKey(page, 'select', 3500);
        await display.screenshot({ path: path.join(outputDir, `${profile.name}-02-details.png`) });

        await pressKey(page, 'select', 3500);
        await display.screenshot({ path: path.join(outputDir, `${profile.name}-03-streams.png`) });

        await pressKey(page, 'select', 9000);
        await pressKey(page, 'select', 1500);
        await display.screenshot({ path: path.join(outputDir, `${profile.name}-04-playback-controls.png`) });
    } finally {
        await page.close();
    }
}

async function pressKey(page, key, delayMs) {
    await page.evaluate((pressedKey) => {
        window.brs.sendKeyPress(pressedKey);
    }, key);
    await sleep(delayMs);
}

function startProcess(command, args, options) {
    return spawn(command, args, {
        ...options,
        stdio: ['ignore', 'pipe', 'pipe'],
    });
}

function stopProcess(child) {
    if (child && !child.killed) {
        child.kill('SIGINT');
    }
}

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
