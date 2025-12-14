# Tasks: MIDIRealtimeToCC

## Phase 1: CLI Version

### Task 1: Project Setup

- [ ] **1.1** Create Xcode Project
  - Use macOS Command Line Tool template
  - Select Swift language
  - Project name: MIDIRealtimeToCC
  - Bundle Identifier: com.example.MIDIRealtimeToCC

- [ ] **1.2** Add CoreMIDI Framework
  - Add CoreMIDI.framework to Linked Frameworks
  - Verify `import CoreMIDI` works

- [ ] **1.3** Create Project Structure
  ```
  MIDIRealtimeToCC/
  ├── main.swift
  ├── Core/
  │   ├── MIDIManager.swift
  │   ├── MessageProcessor.swift
  │   └── ConversionRules.swift
  └── CLI/
      └── CommandLineParser.swift
  ```

### Task 2: MIDIManager Implementation

- [ ] **2.1** MIDIClient Initialization
  - Create client with `MIDIClientCreate`
  - Set up notification callback
  - Implement error handling

- [ ] **2.2** Device Enumeration
  - Get input devices with `MIDIGetNumberOfSources()` / `MIDIGetSource()`
  - Get output devices with `MIDIGetNumberOfDestinations()` / `MIDIGetDestination()`
  - Get device names (`kMIDIPropertyName`)

- [ ] **2.3** Create Input Port
  - Create port with `MIDIInputPortCreate`
  - Implement read callback
  - Connect to device (`MIDIPortConnectSource`)

- [ ] **2.4** Create Output Port
  - Create port with `MIDIOutputPortCreate`
  - Implement message send method
  - Create `MIDISend` wrapper

- [ ] **2.5** Device Connection/Disconnection
  - Search device by name
  - Handle connection errors
  - Cleanup on disconnection

### Task 3: MessageProcessor Implementation

- [ ] **3.1** Message Parsing Foundation
  - Determine status byte
  - Extract data bytes
  - Validate message length

- [ ] **3.2** Real-time Message Processing
  - Detect and convert 0xFA (Start)
  - Detect and convert 0xFB (Continue)
  - Detect and convert 0xFC (Stop)

- [ ] **3.3** Song Position Processing
  - Detect 0xF2
  - Calculate position value from LSB/MSB
  - Determine if position is 0

- [ ] **3.4** Song Select Processing
  - Detect 0xF3
  - Compare with previous value logic
  - Maintain state (lastSongNumber)

- [ ] **3.5** Pass-Through Processing
  - Determine non-conversion target messages
  - Forward unchanged to output

### Task 4: ConversionRules Implementation

- [ ] **4.1** Define Conversion Rule Structure

  ```swift
  struct ConversionRule {
      let inputStatus: UInt8
      let outputCC: UInt8
      let outputValue: UInt8
      let condition: ((Data) -> Bool)?
  }
  ```

- [ ] **4.2** Define Default Rules
  - Start/Continue → CC 80, value 127
  - Stop → CC 80, value 0
  - Song Position (0) → CC 82, value 127
  - Song Select increase → CC 83, value 127
  - Song Select decrease → CC 84, value 127

- [ ] **4.3** Generate CC Messages
  - Status byte (0xB0 + channel)
  - CC number byte
  - Value byte
  - Create MIDIPacket

### Task 5: CommandLineParser Implementation

- [ ] **5.1** Argument Parsing Foundation
  - Process `CommandLine.arguments`
  - Separate flags and option values

- [ ] **5.2** Implement --list
  - Display input device list
  - Display output device list
  - Format output

- [ ] **5.3** Implement --input / --output
  - Get device name
  - Handle names with spaces
  - Verify existence

- [ ] **5.4** Implement --help
  - Display usage
  - Explain options

- [ ] **5.5** Error Handling
  - Error messages for invalid arguments
  - Check required arguments
  - Set exit codes

### Task 6: main.swift Integration

- [ ] **6.1** Initialization Sequence
  - Parse arguments
  - Initialize MIDIManager
  - Connect devices

- [ ] **6.2** Main Loop
  - Wait for events in RunLoop
  - Signal handling (Ctrl+C)

- [ ] **6.3** Log Output
  - Startup message
  - Conversion log (with timestamps)
  - Error log

- [ ] **6.4** Shutdown Process
  - Disconnect devices
  - Release CoreMIDI resources

### Task 7: Testing and Debugging

- [ ] **7.1** Unit Operation Verification
  - Verify device list display
  - Verify connection/disconnection

- [ ] **7.2** Conversion Operation Verification
  - Verify input with MIDI Monitor etc.
  - Verify output via IAC Driver
  - Validate conversion for each message type

- [ ] **7.3** Logic Pro Integration Verification
  - CC recognition in MIDI Learn
  - Transport control operation
  - Latency perception check

---

## Phase 2: Menu Bar UI Version

### Task 8: SwiftUI App Structure

- [ ] **8.1** Project Modification
  - Change to macOS App template
  - Select SwiftUI lifecycle
  - Set LSUIElement = YES (hide Dock icon)

- [ ] **8.2** MenuBarExtra Implementation
  - Create `MenuBarExtra` view
  - Set status icon
  - Define menu structure

- [ ] **8.3** Core Module Integration
  - Reuse Core/ from Phase 1
  - Interface with UI

### Task 9: Device Selection UI

- [ ] **9.1** DeviceSelector View
  - Select device with Picker
  - Display input/output separately
  - Bind selection state

- [ ] **9.2** Device List Update
  - Support hot-plugging
  - Auto-update list

### Task 10: Settings Screen

- [ ] **10.1** Create SettingsView
  - CC number input fields
  - Settings for each conversion rule
  - Display validation

- [ ] **10.2** UserDefaults Integration
  - Persistence with @AppStorage
  - Load/save settings

- [ ] **10.3** Launch at Login Setting
  - ServiceManagement framework
  - Toggle LaunchAtLogin

### Task 11: Status Display

- [ ] **11.1** Connection Status Display
  - Change icon for connected/disconnected
  - Display tooltip

- [ ] **11.2** Activity Display
  - Visual feedback on message reception
  - Display last conversion log

### Task 12: Distribution Preparation

- [ ] **12.1** Code Signing
  - Set Developer ID certificate
  - Enable Hardened Runtime

- [ ] **12.2** Notarization
  - Submit to Apple notarization
  - Stapling

- [ ] **12.3** DMG Creation
  - App bundle
  - Installation instructions

---

## Acceptance Checklist

### Phase 1 Completion Criteria

- [ ] Device list is displayed with `--list`
- [ ] Can connect to specified device
- [ ] Start (0xFA) → converts to CC 80, 127
- [ ] Continue (0xFB) → converts to CC 80, 127
- [ ] Stop (0xFC) → converts to CC 80, 0
- [ ] Song Position (0) → converts to CC 82, 127
- [ ] Song Select increase → converts to CC 83, 127
- [ ] Song Select decrease → converts to CC 84, 127
- [ ] Non-conversion target messages are passed through
- [ ] MIDI Learn works in Logic Pro

### Phase 2 Completion Criteria

- [ ] Resides in menu bar
- [ ] Can select devices from UI
- [ ] Can customize CC numbers
- [ ] Settings are persisted after restart
- [ ] Can configure launch at login
- [ ] Signed and notarized DMG can be created
