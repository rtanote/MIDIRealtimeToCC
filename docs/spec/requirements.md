# Requirements: MIDIRealtimeToCC

## Overview

A macOS application that converts MIDI Real-time messages to Control Change (CC) messages, enabling DAW transport control from MIDI controllers.

---

## User Stories

### US-1: Play/Stop Control

**As a** DAW user
**I want to** control DAW playback/stop using MIDI controller START/STOP buttons
**So that** I can record remotely from my computer

#### Acceptance Criteria

- AC-1.1: Start Message Conversion
  ```
  WHEN the application receives MIDI Real-time Start message (0xFA)
  THE SYSTEM SHALL output CC 80 with value 127 on channel 1
  ```

- AC-1.2: Continue Message Conversion
  ```
  WHEN the application receives MIDI Real-time Continue message (0xFB)
  THE SYSTEM SHALL output CC 80 with value 127 on channel 1
  ```

- AC-1.3: Stop Message Conversion
  ```
  WHEN the application receives MIDI Real-time Stop message (0xFC)
  THE SYSTEM SHALL output CC 80 with value 0 on channel 1
  ```

---

### US-2: Return to Song Start

**As a** DAW user
**I want to** return playback position to song start using MIDI controller RESET button
**So that** I can quickly restart recording

#### Acceptance Criteria

- AC-2.1: Song Position Reset Conversion
  ```
  WHEN the application receives Song Position Pointer message (0xF2) with position 0
  THE SYSTEM SHALL output CC 82 with value 127 on channel 1
  ```

- AC-2.2: Ignore Non-Zero Positions
  ```
  WHEN the application receives Song Position Pointer message (0xF2) with non-zero position
  THE SYSTEM SHALL NOT output any CC message
  ```

---

### US-3: Navigate Between Markers

**As a** DAW user
**I want to** navigate to previous/next markers using SONG SELECT buttons
**So that** I can quickly access specific sections of the song

#### Acceptance Criteria

- AC-3.1: Song Select Increase Conversion
  ```
  WHEN the application receives Song Select message (0xF3) with song number greater than previous
  THE SYSTEM SHALL output CC 83 with value 127 on channel 1
  ```

- AC-3.2: Song Select Decrease Conversion
  ```
  WHEN the application receives Song Select message (0xF3) with song number less than previous
  THE SYSTEM SHALL output CC 84 with value 127 on channel 1
  ```

- AC-3.3: Store Song Select State
  ```
  WHEN the application receives Song Select message (0xF3)
  THE SYSTEM SHALL store the song number for comparison with subsequent messages
  ```

- AC-3.4: First Song Select Processing
  ```
  WHEN the application receives the first Song Select message after startup
  THE SYSTEM SHALL store the song number without outputting any CC message
  ```

---

### US-4: MIDI Pass-Through

**As a** DAW user
**I want to** non-conversion MIDI messages to be forwarded unchanged
**So that** performance data (notes, CC, pitch bend, etc.) is not lost

#### Acceptance Criteria

- AC-4.1: Note Message Pass-Through
  ```
  WHEN the application receives Note On or Note Off messages
  THE SYSTEM SHALL forward them unchanged to the output device
  ```

- AC-4.2: CC Message Pass-Through
  ```
  WHEN the application receives Control Change messages
  THE SYSTEM SHALL forward them unchanged to the output device
  ```

- AC-4.3: Other Message Pass-Through
  ```
  WHEN the application receives any MIDI message not specified for conversion
  THE SYSTEM SHALL forward it unchanged to the output device
  ```

---

### US-5: Device Selection (CLI)

**As a** user
**I want to** specify input and output MIDI devices from command line
**So that** I can configure for my environment

#### Acceptance Criteria

- AC-5.1: Device List Display
  ```
  WHEN the user runs the application with --list flag
  THE SYSTEM SHALL display all available MIDI input and output devices
  ```

- AC-5.2: Input Device Specification
  ```
  WHEN the user specifies --input with a device name
  THE SYSTEM SHALL connect to that device as MIDI input source
  ```

- AC-5.3: Output Device Specification
  ```
  WHEN the user specifies --output with a device name
  THE SYSTEM SHALL connect to that device as MIDI output destination
  ```

- AC-5.4: Invalid Device Name Error Handling
  ```
  WHEN the user specifies a device name that does not exist
  THE SYSTEM SHALL display an error message and exit with non-zero status
  ```

---

### US-6: Menu Bar UI (Phase 2)

**As a** user
**I want to** control the application from menu bar
**So that** I can easily configure and check status via GUI

#### Acceptance Criteria

- AC-6.1: Menu Bar Residence
  ```
  WHEN the application is running
  THE SYSTEM SHALL display an icon in the macOS menu bar
  ```

- AC-6.2: Device Selection UI
  ```
  WHEN the user clicks the menu bar icon
  THE SYSTEM SHALL display a menu with input and output device selection
  ```

- AC-6.3: Settings Persistence
  ```
  WHEN the user selects input or output devices
  THE SYSTEM SHALL persist the selection and restore it on next launch
  ```

---

### US-7: CC Number Customization (Phase 2)

**As a** user
**I want to** change output CC numbers
**So that** I can avoid conflicts with existing CC assignments

#### Acceptance Criteria

- AC-7.1: CC Number Settings UI
  ```
  WHEN the user opens the settings panel
  THE SYSTEM SHALL display CC number fields for each conversion rule
  ```

- AC-7.2: CC Number Range Validation
  ```
  WHEN the user enters a CC number outside 0-127
  THE SYSTEM SHALL display a validation error and reject the input
  ```

- AC-7.3: CC Settings Persistence
  ```
  WHEN the user changes CC number settings
  THE SYSTEM SHALL persist the settings and apply them immediately
  ```

---

## Out of Scope

- MIDI 2.0 protocol support
- Windows/Linux support
- Simultaneous use of multiple input devices
- Audio Unit / MIDI FX plugin format
