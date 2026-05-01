# Android release assets

The `android-release-assets` GitHub Actions workflow builds ABI-specific
archives for ConnectBot:

- `mosh-android-arm64-v8a.zip`
- `mosh-android-armeabi-v7a.zip`
- `mosh-android-x86.zip`
- `mosh-android-x86_64.zip`

Each archive contains:

- `libmosh-client.so`, a native mosh client binary
- `terminfo.zip`, the terminfo database needed by the client

These assets are GPL-licensed as part of mosh. Apps that consume them should
present that license fact before downloading or enabling the binary.
