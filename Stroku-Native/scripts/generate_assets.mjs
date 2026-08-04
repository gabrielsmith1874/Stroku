import fs from 'fs';
import path from 'path';
import { PNG } from 'pngjs';
import fetch from 'node-fetch';
import { Resvg } from '@resvg/resvg-js';
import QRCode from 'qrcode';

const outDir = path.resolve('images');

const supportUrl = 'https://buymeacoffee.com/gabrielsmith';

async function downloadIcon(name, iconifyId, size = 128) {
  const url = `https://api.iconify.design/${iconifyId}.svg?color=white&width=${size}&height=${size}`;
  console.log(`Downloading ${name} from ${url}...`);
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to download ${name}: ${res.statusText}`);
  const svg = await res.text();
  
  const resvg = new Resvg(svg, {
    background: 'rgba(0,0,0,0)',
    fitTo: { mode: 'width', value: size }
  });
  
  const pngData = resvg.render();
  const pngBuffer = pngData.asPng();
  fs.writeFileSync(path.join(outDir, `${name}.png`), pngBuffer);
}

function generateVignette() {
  console.log('Generating vignette.png...');
  const height = 512;
  const width = 1;
  const png = new PNG({ width, height });

  for (let y = 0; y < height; y++) {
    const progress = y / height;
    const eased = Math.pow(progress, 1.5);
    const alpha = Math.floor(eased * 240);

    const idx = (width * y) << 2;
    png.data[idx] = 0;     // R
    png.data[idx + 1] = 0; // G
    png.data[idx + 2] = 0; // B
    png.data[idx + 3] = alpha;
  }

  const buffer = PNG.sync.write(png);
  fs.writeFileSync(path.join(outDir, 'vignette.png'), buffer);
}

// Phone cameras need a light quiet zone around the modules, so this one code is
// drawn dark-on-white rather than following the app's dark palette.
async function generateSupportQr() {
  console.log('Generating qr_coffee.png...');
  const buffer = await QRCode.toBuffer(supportUrl, {
    type: 'png',
    width: 480,
    margin: 3,
    errorCorrectionLevel: 'M',
    color: { dark: '#0B0A18FF', light: '#FFFFFFFF' }
  });
  fs.writeFileSync(path.join(outDir, 'qr_coffee.png'), buffer);
}

async function main() {
  try {
    generateVignette();
    await generateSupportQr();
    
    // Download Material Icons
    await downloadIcon('icon_play', 'mdi/play', 128);
    await downloadIcon('icon_pause', 'mdi/pause', 128);
    await downloadIcon('icon_next', 'mdi/skip-next', 128);
    await downloadIcon('icon_subtitles', 'mdi/subtitles-outline', 96);
    await downloadIcon('icon_settings', 'mdi/speedometer', 96); // using speedometer for "speed/settings"
    await downloadIcon('icon_episodes', 'mdi/animation-play-outline', 96); // close/episodes
    await downloadIcon('icon_seeds', 'mdi/account-multiple-outline', 96);
    await downloadIcon('icon_size', 'mdi/database-outline', 96);
    await downloadIcon('icon_tracker', 'mdi/web', 96);

    console.log('Successfully generated and downloaded all assets!');
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
