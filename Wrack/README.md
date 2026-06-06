# Wrack WASM Autosplitter

Port of [Dalet's Wrack Autosplitter](https://github.com/Dalet/LiveSplit.Wrack) in rust to support Livesplit One on Linux. It support the same feature.

Tested only on the Steam version running through Protons

## Features

- Automatic splitting
- Automatic reset
- In-Game time

## Build

```sh
cargo build --target wasm32-unknown-unknown --release
```
