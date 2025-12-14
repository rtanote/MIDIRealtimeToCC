//
//  MessageProcessor.swift
//  MIDIRealtimeToCC
//
//  Processes incoming MIDI messages and converts them to CC messages
//

import Foundation
import CoreMIDI

/// Processes MIDI messages and performs conversions
class MessageProcessor {
    private let rules = ConversionRules.shared
    private var lastSongNumber: UInt8?
    var isEnabled: Bool = true

    /// Callback for sending converted messages
    var onConvertedMessage: (([UInt8]) -> Void)?

    /// Callback for passing through non-converted messages
    var onPassThroughMessage: (([UInt8]) -> Void)?

    /// Callback for logging
    var onLog: ((String) -> Void)?

    init() {}

    /// Process incoming MIDI message bytes
    func processMessage(_ bytes: [UInt8]) {
        guard isEnabled, !bytes.isEmpty else { return }

        let status = bytes[0]

        // Check if this is a Real-time message (0xF8-0xFF)
        if status >= 0xF8 {
            handleRealtimeMessage(bytes)
        }
        // Check if this is a System Common message (0xF0-0xF7)
        else if status >= 0xF0 && status <= 0xF7 {
            handleSystemCommonMessage(bytes)
        }
        // Pass through all other messages (channel messages, etc.)
        else {
            passThroughMessage(bytes)
        }
    }

    private func handleRealtimeMessage(_ bytes: [UInt8]) {
        let status = bytes[0]

        // Check against conversion rules
        for rule in rules.rules {
            if rule.matches(bytes) {
                let result = rule.convert(channel: rules.defaultChannel)
                let ccBytes = rules.createCCPacket(result: result)
                sendConvertedMessage(ccBytes, original: bytes)
                return
            }
        }

        // If no rule matched, pass through
        passThroughMessage(bytes)
    }

    private func handleSystemCommonMessage(_ bytes: [UInt8]) {
        let status = bytes[0]

        switch status {
        case 0xF2: // Song Position Pointer
            handleSongPosition(bytes)

        case 0xF3: // Song Select
            handleSongSelect(bytes)

        default:
            // Pass through other System Common messages
            passThroughMessage(bytes)
        }
    }

    private func handleSongPosition(_ bytes: [UInt8]) {
        // Check against conversion rules (position = 0)
        for rule in rules.rules {
            if rule.matches(bytes) {
                let result = rule.convert(channel: rules.defaultChannel)
                let ccBytes = rules.createCCPacket(result: result)
                sendConvertedMessage(ccBytes, original: bytes)
                return
            }
        }

        // If position is not 0, pass through
        passThroughMessage(bytes)
    }

    private func handleSongSelect(_ bytes: [UInt8]) {
        guard bytes.count >= 2 else {
            passThroughMessage(bytes)
            return
        }

        let songNumber = bytes[1]

        // Check if we have a previous song number to compare
        if let previous = lastSongNumber {
            if songNumber > previous {
                // Increase → Next marker (CC 83)
                let result = ConversionResult(
                    cc: rules.ccNextMarker,
                    value: 127,
                    channel: rules.defaultChannel
                )
                let ccBytes = rules.createCCPacket(result: result)
                sendConvertedMessage(ccBytes, original: bytes)
            } else if songNumber < previous {
                // Decrease → Previous marker (CC 84)
                let result = ConversionResult(
                    cc: rules.ccPrevMarker,
                    value: 127,
                    channel: rules.defaultChannel
                )
                let ccBytes = rules.createCCPacket(result: result)
                sendConvertedMessage(ccBytes, original: bytes)
            } else {
                // Same value, pass through
                passThroughMessage(bytes)
            }
        } else {
            // First time, just store and pass through
            passThroughMessage(bytes)
        }

        // Store for next comparison
        lastSongNumber = songNumber
    }

    private func sendConvertedMessage(_ ccBytes: [UInt8], original: [UInt8]) {
        onConvertedMessage?(ccBytes)

        // Log the conversion
        let originalHex = original.map { String(format: "0x%02X", $0) }.joined(separator: " ")
        let ccHex = ccBytes.map { String(format: "0x%02X", $0) }.joined(separator: " ")
        onLog?("[\(originalHex)] → [\(ccHex)]")
    }

    private func passThroughMessage(_ bytes: [UInt8]) {
        onPassThroughMessage?(bytes)
    }

    /// Reset state (e.g., when reconnecting devices)
    func reset() {
        lastSongNumber = nil
    }
}
