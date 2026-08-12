# MacOS::AudioDevices

Small CoreAudio wrapper for macOS, written in Raku.

This module can:

- list audio devices
- list input-only, output-only, and duplex devices
- inspect active default input and output device
- switch default output device by name or id

## Platform

This distribution is macOS-only. It calls CoreAudio via NativeCall.

## Install

```bash
zef install .
```

## Quick Start

```raku
use MacOS::AudioDevices;

say "All devices:";
.say for MacOS::AudioDevices.audio-devices();

say "Active output:";
say MacOS::AudioDevices.active-output-device();
```

## API

### `audio-devices --> Array`

Returns an array of hashes shaped like:

```raku
{ id => Int, name => Str }
```

### `audio-input-devices --> Array`

Returns devices with input streams.

### `audio-output-devices --> Array`

Returns devices with output streams.

### `duplex-audio-devices --> Array`

Returns devices that are both input and output capable.

### `active-input-device --> Hash`

Returns the current default input device hash.

### `active-output-device --> Hash`

Returns the current default output device hash.

### `set-output-device(Str $name) --> Bool`

Switches default output by exact device name.

### `set-output-device(Int $id) --> Bool`

Switches default output by device id.

## Development

Run basic distribution tests:

```bash
raku -Ilib t/00-load.t
raku -Ilib t/01-public-api.t
```

Ad-hoc scripts are in `test/`.

## License

GPL-3.0-or-later. See `LICENSE`.
