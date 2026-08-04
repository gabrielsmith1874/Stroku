# Stroku

Stroku is a cross-device media streaming project that connects an Android sender with a Roku receiver.

## Components

- [`StreamBridge/`](StreamBridge/) — Android sender application built with Kotlin.
- [`StreamCast-Receiver/`](StreamCast-Receiver/) — Roku receiver application built with BrightScript.

## Project flow

```text
Android phone  →  StreamBridge  →  local network  →  StreamCast Receiver  →  Roku TV
```

Each component keeps its own build and deployment workflow. See the component directory for platform-specific setup instructions.

## License

See the component directories for the original project licenses and notices.
