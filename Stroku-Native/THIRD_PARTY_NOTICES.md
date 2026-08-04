# Third-party notices

This file records the direct development-time dependencies and generated icon
source used by Stroku Native. The Node.js tools are not bundled into the Roku
channel package.

## Direct development dependencies

| Package | Version | License | Source |
| --- | --- | --- | --- |
| `@resvg/resvg-js` | 2.6.2 | MPL-2.0 | [resvg-js](https://github.com/yisibl/resvg-js) |
| `node-fetch` | 3.3.2 | MIT | [node-fetch](https://github.com/node-fetch/node-fetch) |
| `playwright` | 1.62.1 | Apache-2.0 | [Playwright](https://github.com/microsoft/playwright) |
| `pngjs` | 7.0.0 | MIT | [pngjs](https://github.com/pngjs/pngjs) |
| `qrcode` | 1.5.4 | MIT | [node-qrcode](https://github.com/soldair/node-qrcode) |

Transitive packages are recorded in `package-lock.json`; their upstream
licenses remain applicable when the development tools are installed.

## Generated icons

`scripts/generate_assets.mjs` downloads the Material Design Icons listed in the
script through Iconify and rasterizes them for the Roku UI. Material Design
Icons are distributed under Apache-2.0; see the
[MaterialDesign repository](https://github.com/Templarian/MaterialDesign) for
the upstream notices.

The support QR code, vignette, stream metadata icons, and Stroku branding
assets are generated or authored for this project. Verify ownership before
reusing them outside Stroku Native.

## External services and trademarks

Stroku Native can connect to Stremio services and user-supplied add-ons, but it
does not operate those services or redistribute their content. Roku and
Stremio are trademarks of their respective owners. Stroku Native is an
independent project and is not endorsed by either company.
