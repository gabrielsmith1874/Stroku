# Stroku

Stroku is a cross-device media streaming project connecting Android, Roku,
and the supporting client experiences around them.

## Components

- [`Stroku-Native/`](Stroku-Native/) - a native Roku client for metadata,
  libraries, add-ons, and direct playback.
- [`StreamBridge/`](StreamBridge/) - an Android sender application built with
  Kotlin.
- [`StreamCast-Receiver/`](StreamCast-Receiver/) - a Roku receiver built with
  BrightScript.

## Project flow

```text
Android phone -> StreamBridge -> local network -> StreamCast Receiver -> Roku TV
                                                       ^
                                                       |
                                      Stroku Native is a standalone Roku client
```

Each component keeps its own build and deployment workflow. Start with the
README inside the component you want to develop.

## Contributions

This repository accepts contributions through forks and pull requests. The
`main` branch is protected; see [CONTRIBUTING.md](CONTRIBUTING.md) and the
pull request template before opening a change.

## Public export scope

The `Stroku-Native/` component is a clean public export of reviewed source and
tests. It intentionally excludes the private development checkout, discarded
Git objects, local configuration, build output, and Stremio web-crawl notes and
screenshots pending separate ownership and trademark review.

## Licensing and notices

This repository is distributed under the MIT License, with third-party
material and component-specific notices documented in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
