# Design: MIDIRealtimeToCC

## Overview

This document defines the technical design of the MIDIRealtimeToCC application.

---

## Architecture

### System Context

```
┌─────────────────────┐
│   MIDI Controller   │
│ (e.g., Roland A-70) │
└──────────┬──────────┘
           │ USB/MIDI
           ▼
┌──────────────────────────────────────────┐
│              macOS                        │
│  ┌────────────────────────────────────┐  │
│  │           CoreMIDI                  │  │
│  └──────────────┬─────────────────────┘  │
│                 │                         │
│  ┌──────────────▼─────────────────────┐  │
│  │       MIDIRealtimeToCC             │  │
│  │  ┌─────────┐  ┌─────────────────┐  │  │
│  │  │ Input   │  │ Message         │  │  │
│  │  │ Handler │─▶│ Processor       │  │  │
│  │  └─────────┘  └────────┬────────┘  │  │
│  │                        │           │  │
│  │               ┌────────▼────────┐  │  │
│  │               │ Output Handler  │  │  │
│  │               └────────┬────────┘  │  │
│  └────────────────────────┼───────────┘  │
│                           │              │
│  ┌────────────────────────▼───────────┐  │
│  │           IAC Driver               │  │
│  └────────────────────────┬───────────┘  │
│                           │              │
│  ┌────────────────────────▼───────────┐  │
│  │           Logic Pro                │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### Component Architecture

```
MIDIRealtimeToCC
├── Core/
│   ├── MIDIManager          # CoreMIDI connection management
│   ├── MessageProcessor     # Message conversion logic
│   └── ConversionRules      # Conversion rule definitions
├── CLI/
│   └── CommandLineParser    # CLI argument processing
└── UI/ (Phase 2)
    ├── MenuBarApp           # Menu bar application
    ├── SettingsView         # Settings screen
    └── DeviceSelector       # Device selection UI
```

---

## Data Flow

### Message Processing Sequence

```
┌──────────┐     ┌─────────────┐     ┌──────────────────┐     ┌──────────┐
│  Input   │     │   MIDI      │     │    Message       │     │  Output  │
│  Device  │     │  Manager    │     │   Processor      │     │  Device  │
└────┬─────┘     └──────┬──────┘     └────────┬─────────┘     └────┬─────┘
     │                  │                      │                    │
     │  MIDI Message    │                      │                    │
     │─────────────────▶│                      │                    │
     │                  │                      │                    │
     │                  │  Raw Bytes           │                    │
     │                  │─────────────────────▶│                    │
     │                  │                      │                    │
     │                  │                      │ Check message type │
     │                  │                      │◀─────────────────┐ │
     │                  │                      │                  │ │
     │                  │                      │─────────────────▶│ │
     │                  │                      │                    │
     │                  │                      │ [Conversion Target]│
     │                  │                      │ Convert to CC      │
     │                  │                      │────────────────────▶
     │                  │                      │                    │
     │                  │                      │ [Pass-through]     │
     │                  │                      │ Forward unchanged  │
     │                  │                      │────────────────────▶
     │                  │                      │                    │
```

### Conversion Decision Flow

```
                    ┌─────────────────┐
                    │ Receive Message │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Get Status Byte │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐     ┌──────▼──────┐    ┌─────▼─────┐
    │ 0xFA/FB/FC│     │    0xF2     │    │   0xF3    │
    │ Start/    │     │ Song Pos    │    │ Song Sel  │
    │ Continue/ │     └──────┬──────┘    └─────┬─────┘
    │ Stop      │            │                 │
    └─────┬─────┘     ┌──────▼──────┐   ┌──────▼──────┐
          │          │ Position=0? │   │ Compare to  │
    ┌─────▼─────┐     └──────┬──────┘   │ Previous    │
    │ Output    │            │          └──────┬──────┘
    │ CC 80     │     ┌──────┴──────┐          │
    └───────────┘     │Yes      No  │   ┌──────┴──────┐
                      ▼             ▼   │Inc    Dec   │
               ┌──────────┐  ┌──────┐   ▼             ▼
               │Output    │  │ Pass │  ┌────────┐ ┌────────┐
               │CC 82     │  │through│ │Output  │ │Output  │
               └──────────┘  └──────┘  │CC 83   │ │CC 84   │
                                       └────────┘ └────────┘
```

---

## Technical Specifications

### CoreMIDI Integration

#### Client Setup

```swift
var midiClient: MIDIClientRef = 0
var inputPort: MIDIPortRef = 0
var outputPort: MIDIPortRef = 0

// Create client
MIDIClientCreate("MIDIRealtimeToCC" as CFString, notifyCallback, nil, &midiClient)

// Create input port
MIDIInputPortCreate(midiClient, "Input" as CFString, readCallback, nil, &inputPort)

// Create output port
MIDIOutputPortCreate(midiClient, "Output" as CFString, &outputPort)
```

#### Read Callback

```swift
let readCallback: MIDIReadProc = { packetList, srcConnRefCon, connRefCon in
    let packets = packetList.pointee
    var packet = packets.packet
    
    for _ in 0..<packets.numPackets {
        let bytes = Mirror(reflecting: packet.data).children.map { $0.value as! UInt8 }
        let length = Int(packet.length)
        
        processMessage(Array(bytes.prefix(length)))
        
        packet = MIDIPacketNext(&packet).pointee
    }
}
```

### Message Format

#### Input Messages

| Message | Status | Data Bytes | Total |
|---------|--------|------------|-------|
| Start | 0xFA | none | 1 |
| Continue | 0xFB | none | 1 |
| Stop | 0xFC | none | 1 |
| Song Position | 0xF2 | LSB, MSB | 3 |
| Song Select | 0xF3 | song number | 2 |

#### Output Messages

| Message | Status | Data 1 | Data 2 | Total |
|---------|--------|--------|--------|-------|
| CC | 0xB0 | CC number | value | 3 |

### Conversion Rules

```swift
struct ConversionRule {
    let inputStatus: UInt8
    let outputCC: UInt8
    let outputValue: UInt8
    let condition: ((Data) -> Bool)?
}

let defaultRules: [ConversionRule] = [
    // Start → CC 80, value 127
    ConversionRule(inputStatus: 0xFA, outputCC: 80, outputValue: 127, condition: nil),
    
    // Continue → CC 80, value 127
    ConversionRule(inputStatus: 0xFB, outputCC: 80, outputValue: 127, condition: nil),
    
    // Stop → CC 80, value 0
    ConversionRule(inputStatus: 0xFC, outputCC: 80, outputValue: 0, condition: nil),
    
    // Song Position (pos=0) → CC 82, value 127
    ConversionRule(inputStatus: 0xF2, outputCC: 82, outputValue: 127, 
                   condition: { $0[1] == 0 && $0[2] == 0 }),
]
```

### State Management

```swift
class ConverterState {
    var lastSongNumber: UInt8? = nil
    var isEnabled: Bool = true
    
    func processSongSelect(_ songNumber: UInt8) -> ConversionResult? {
        defer { lastSongNumber = songNumber }
        
        guard let previous = lastSongNumber else {
            return nil  // No output for first time
        }

        if songNumber > previous {
            return .init(cc: 83, value: 127)  // Increase → next marker
        } else if songNumber < previous {
            return .init(cc: 84, value: 127)  // Decrease → previous marker
        }
        return nil  // Ignore same value
    }
}
```

---

## Configuration

### Phase 1: CLI Arguments

```
Usage: MIDIRealtimeToCC [options]

Options:
  --list              List available MIDI devices
  --input <name>      Specify input device name
  --output <name>     Specify output device name
  --help              Show help message
  --version           Show version information
```

### Phase 2: UserDefaults Schema

| Key | Type | Description |
|-----|------|-------------|
| `inputDeviceUID` | String | Input device unique ID |
| `outputDeviceUID` | String | Output device unique ID |
| `ccStart` | Int | Output CC number for Start/Continue |
| `ccStop` | Int | Output CC number for Stop |
| `ccSongPosition` | Int | Output CC number for Song Position Reset |
| `ccNextMarker` | Int | Output CC number for Song Select increase |
| `ccPrevMarker` | Int | Output CC number for Song Select decrease |
| `launchAtLogin` | Bool | Launch at login |

---

## Error Handling

### Device Connection Errors

| Error | Handling |
|-------|----------|
| Device not found | Display error message and exit (CLI) / Show alert (UI) |
| Device disconnected | Attempt reconnection, notify on failure |
| Permission denied | Guide message to System Preferences |

### Runtime Errors

| Error | Handling |
|-------|----------|
| CoreMIDI initialization failure | Log error, exit |
| Output send failure | Log error, continue processing |

---

## Performance Considerations

### Latency Budget

| Component | Target | Notes |
|-----------|--------|-------|
| CoreMIDI callback | < 100μs | System dependent |
| Message processing | < 50μs | Simple conditional branching only |
| Output send | < 100μs | System dependent |
| **Total** | **< 1ms** | Below human perception threshold |

### Memory Usage

| Component | Estimate |
|-----------|----------|
| CoreMIDI resources | ~5MB |
| Application code | ~2MB |
| UI resources (Phase 2) | ~10MB |
| **Total** | **< 50MB** |

---

## Security Considerations

### macOS Permissions

- **Input Monitoring**: Required for access to MIDI input devices
- **Automation**: Not required (no control of other applications)

### Code Signing

Required for Phase 2 UI version distribution:

- Developer ID Application certificate
- Notarization

---

## Testing Strategy

### Unit Tests

- `ConversionRules`: Verify input/output for each conversion rule
- `ConverterState`: Verify Song Select state transitions
- `MessageProcessor`: Verify message determination logic

### Integration Tests

- CoreMIDI connection/disconnection scenarios
- Message transmission/reception via IAC Driver
- Device hot-plugging support

### Manual Tests

- Verify operation with actual hardware (Roland A-70)
- Verify MIDI Learn operation in Logic Pro
