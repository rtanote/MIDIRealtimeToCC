# MIDIRealtimeToCC Specification

## Overview

MIDIRealtimeToCC is a macOS application that converts MIDI Real-time messages and System Common messages to Control Change (CC) messages. This enables DAW (e.g., Logic Pro) transport control from MIDI controller sequencer buttons.

### Background

MIDI Real-time messages (Start/Stop/Continue) are consumed by most DAWs' sync functionality and never reach the standard MIDI Learn feature. This application converts these messages to generic CC messages, making them learnable by DAW controller assignment features.

## User Stories

### US-1: Basic Play/Stop Control

**As a** DAW user
**I want to** control DAW playback/stop using MIDI controller START/STOP buttons
**So that** I can record remotely from my computer

#### Acceptance Criteria

- [ ] When receiving MIDI Real-time Start message (0xFA), output CC 80 with value 127
- [ ] When receiving MIDI Real-time Continue message (0xFB), output CC 80 with value 127
- [ ] When receiving MIDI Real-time Stop message (0xFC), output CC 80 with value 0

### US-2: Return to Song Start

**As a** DAW user
**I want to** return playback position to song start using MIDI controller RESET button
**So that** I can quickly restart recording

#### Acceptance Criteria

- [ ] When receiving Song Position Pointer (0xF2) with position 0, output CC 82 with value 127

### US-3: Navigate Between Markers

**As a** DAW user
**I want to** navigate to previous/next markers using SONG SELECT buttons
**So that** I can quickly access specific sections of the song

#### Acceptance Criteria

- [ ] When Song Select (0xF3) song number increases from previous, output CC 83 with value 127
- [ ] When Song Select (0xF3) song number decreases from previous, output CC 84 with value 127
- [ ] Application remembers previous song number for comparison

### US-4: MIDI Device Selection

**As a** user
**I want to** select input and output MIDI devices
**So that** I can configure for my environment

#### Acceptance Criteria

- [ ] Can display list of MIDI devices connected to the system
- [ ] Can select one input device
- [ ] Can select one output device
- [ ] Selected devices are restored on next launch

### US-5: CC Number Customization (Phase 2)

**As a** user
**I want to** customize output CC numbers
**So that** I can avoid conflicts with existing CC assignments

#### Acceptance Criteria

- [ ] Can change output CC number for each conversion rule in range 0-127
- [ ] Settings are persisted after application exit

## Technical Design

### Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────┐
│ MIDI Controller │────▶│  MIDIRealtimeToCC    │────▶│ IAC Driver  │
│   (e.g., A-70)  │     │                      │     │             │
└─────────────────┘     │  ┌────────────────┐  │     └──────┬──────┘
                        │  │ Message Filter │  │            │
                        │  └───────┬────────┘  │            ▼
                        │          │           │     ┌─────────────┐
                        │  ┌───────▼────────┐  │     │  Logic Pro  │
                        │  │   Converter    │  │     │             │
                        │  └───────┬────────┘  │     └─────────────┘
                        │          │           │
                        │  ┌───────▼────────┐  │
                        │  │  Pass-through  │  │
                        │  └────────────────┘  │
                        └──────────────────────┘
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift |
| MIDI API | CoreMIDI |
| UI (Phase 2) | SwiftUI |
| App Form | Phase 1: CLI / Phase 2: Menu Bar Application |
| Minimum OS | macOS 12.0 (Monterey) |

### Data Flow

1. Receive MIDI messages on CoreMIDI input port
2. Determine message type
3. If conversion target: Convert to CC message and output
4. If not conversion target: Pass through unchanged

### Conversion Table

| Input Message | Bytes | Output CC | Output Value | Notes |
|--------------|-------|-----------|--------------|-------|
| Start | 0xFA | 80 | 127 | Start playback |
| Continue | 0xFB | 80 | 127 | Resume playback (same as Start) |
| Stop | 0xFC | 80 | 0 | Stop playback |
| Song Position (pos=0) | 0xF2 0x00 0x00 | 82 | 127 | Respond only to position 0 |
| Song Select (increase) | 0xF3 nn | 83 | 127 | Compare with previous value |
| Song Select (decrease) | 0xF3 nn | 84 | 127 | Compare with previous value |

### State Management

```swift
struct ConverterState {
    var lastSongNumber: UInt8? = nil  // For Song Select comparison
    var isEnabled: Bool = true        // Enable/disable conversion
}
```

## Development Phases

### Phase 1: CLI Version (Proof of Concept)

#### Scope

- MIDI input/output via CoreMIDI
- Conversion logic implementation
- Device selection via command-line arguments
- Fixed CC numbers

#### CLI Specification

```bash
# List devices
MIDIRealtimeToCC --list

# Start conversion
MIDIRealtimeToCC --input "Roland A-70" --output "IAC Driver Bus 1"

# Help
MIDIRealtimeToCC --help
```

#### Output Example

```
MIDIRealtimeToCC v0.1.0
Input:  Roland A-70
Output: IAC Driver Bus 1
Listening... (Press Ctrl+C to quit)

[12:34:56] 0xFA Start → CC 80 val 127
[12:34:58] 0xFC Stop  → CC 80 val 0
```

### Phase 2: Menu Bar UI Version

#### Scope

- Menu bar application using SwiftUI
- Settings screen (input/output devices, CC number customization)
- Settings persistence (UserDefaults)
- Launch at login option

#### UI Structure

```
Menu Bar Icon
    ├── Status (Enabled/Disabled)
    ├── ─────────────
    ├── Input: [Device Selection ▼]
    ├── Output: [Device Selection ▼]
    ├── ─────────────
    ├── Settings... (CC number customization)
    ├── Launch at Login ☑
    ├── ─────────────
    └── Quit
```

## Non-Functional Requirements

### Performance

- MIDI message processing latency: < 1ms
- CPU usage: < 1% when idle
- Memory usage: < 50MB

### Reliability

- Support MIDI device hot-plugging (automatic reconnection)
- Error handling when selected device is not found

### Compatibility

- Works with all CoreMIDI-compatible MIDI interfaces
- Compatible with CC Learn features in Logic Pro, GarageBand, MainStage, etc.

## Glossary

| Term | Description |
|------|-------------|
| MIDI Real-time Messages | System Real-time messages (0xF8-0xFF). Includes Timing Clock, Start, Stop, Continue, etc. |
| CC (Control Change) | MIDI channel message type. Has controller number (0-127) and value |
| IAC Driver | macOS built-in virtual MIDI bus. Enables MIDI transfer between applications |
| MIDI Learn | Feature where DAW monitors MIDI input and assigns received messages to functions |

## References

- [CoreMIDI Framework Reference](https://developer.apple.com/documentation/coremidi)
- [MIDI 1.0 Specification](https://www.midi.org/specifications)
- Roland A-70 Owner's Manual
