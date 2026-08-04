<div align="center">

# Stroku Native

### A native Roku client for Stremio metadata, libraries, add-ons, and direct playback

<p>
  <img src="https://img.shields.io/badge/platform-Roku-662D91?style=flat-square" alt="Roku" />
  <img src="https://img.shields.io/badge/runtime-SceneGraph-8B5CF6?style=flat-square" alt="SceneGraph" />
  <img src="https://img.shields.io/badge/version-0.1.0-F59E0B?style=flat-square" alt="Version 0.1.0" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22C55E?style=flat-square" alt="MIT License" /></a>
</p>

Browse your Stremio library from the couch, install add-ons from your own manifest URLs, and play direct HTTP(S) media streams with a Roku remote.

</div>

## What Stroku does

- Browse Cinemeta movie and series metadata with the Roku remote.
- Connect a Stremio account through the official link-code flow.
- Browse, add, remove, and sync library items.
- Explore series with seasons, episodes, air dates, descriptions, and progress.
- Install multiple stream and subtitle add-ons from manifest URLs.
- Match add-ons by their declared resources, types, and ID prefixes.
- Play direct HTTP(S) media URLs and select subtitle tracks.
- Customize subtitle appearance and playback settings.
- Accept direct media URLs through Roku deep linking with `contentId`.

## What it does not do

Stroku is a client, not a content service. It does not host, index, cache, or distribute media, and it has no torrent engine. Raw torrent-only, magnet, YouTube-ID, external-page, catalog, and metadata results are not playable in this version.

## How it works

```text
Your Roku  <->  Stroku Native  <->  Stremio metadata / account services
                                  \-> add-ons you install yourself
                                  \-> direct HTTP(S) media URLs
```

Add-ons are supplied by the user through a manifest URL. Stroku stores configured add-ons and the Stremio auth key in the Roku registry; it does not operate or control third-party add-ons.

## Quick start

### 1. Package the channel

Requires Node.js and a Roku device in developer mode.

```powershell
npm install
npm run package
```

Sideload `dist/stroku-native.zip` through Roku developer mode.

### 2. Add stream or subtitle add-ons

While Stroku is open, visit the phone setup address shown in the upper-right corner of the TV. Paste a complete `https://.../manifest.json` URL and select **Add to Roku**. Your phone and Roku must be on the same local network.

### 3. Connect Stremio

Press `*` on the home screen, choose **Connect Stremio**, then open the displayed `link.stremio.com` URL on another device and approve the connection. Once connected, your library and watch history can be accessed from the Roku.

## Development

Run the checks locally:

```powershell
npm test
```

The mock add-on server exercises direct streams, subtitle results, malformed manifests, and torrent-only filtering without changing the production package:

```powershell
node tests/mock-addon-server.mjs
powershell -ExecutionPolicy Bypass -File tests/build-mock-package.ps1
```

For a provider-neutral manifest fixture:

```powershell
powershell -ExecutionPolicy Bypass -File tests/build-mock-package.ps1 `
  -ManifestUrl "http://127.0.0.1:7319/generic/manifest.json"
```

## Documentation

- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

Research notes and UI reference captures are intentionally excluded from this
public export pending separate ownership and trademark review.

## Limitations

Playback depends on the protocols, codecs, and subtitle formats supported by the Roku model. Roku-specific behavior still needs testing on physical devices, especially playback headers, codec compatibility, local setup, and registry persistence.

## Disclaimer

<details>
<summary>Read the project disclaimer</summary>

Stroku is a free, open-source client application. It hosts, indexes, caches, and distributes no media content, operates no content servers, and maintains no catalogue of sources. It has no torrent client and cannot process magnet links, `.torrent` files, or peer-to-peer swarms; results that are not directly playable HTTP(S) media URLs are rejected before playback.

The only add-on included by default is Cinemeta, the official Stremio metadata catalogue, which supplies titles, artwork, and descriptions only. Every other add-on is installed by the user from a manifest URL the user supplies. This project does not recommend, rank, bundle, link to, or distribute third-party add-ons, and does not operate or control any add-on you install.

Users are responsible for ensuring that the sources they connect and the content they access are lawful in their jurisdiction. Do not use this software to infringe copyright or to circumvent access controls.

Stroku is an independent project and is not affiliated with, endorsed by, or associated with Roku, Inc. or Stremio. All trademarks are the property of their respective owners.

Provided “as is”, without warranty of any kind. See [LICENSE](LICENSE).

</details>
