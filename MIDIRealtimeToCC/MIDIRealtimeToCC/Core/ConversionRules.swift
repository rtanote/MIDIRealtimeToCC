//
//  ConversionRules.swift
//  MIDIRealtimeToCC
//
//  Defines conversion rules from MIDI Real-time/System Common messages to CC messages
//

import Foundation
import CoreMIDI

/// Result of a conversion operation
struct ConversionResult {
    let cc: UInt8
    let value: UInt8
    let channel: UInt8

    init(cc: UInt8, value: UInt8, channel: UInt8 = 0) {
        self.cc = cc
        self.value = value
        self.channel = channel
    }
}

/// Conversion rule definition
struct ConversionRule {
    let inputStatus: UInt8
    let outputCC: UInt8
    let outputValue: UInt8
    let condition: (([UInt8]) -> Bool)?

    func matches(_ bytes: [UInt8]) -> Bool {
        guard !bytes.isEmpty else { return false }
        guard bytes[0] == inputStatus else { return false }

        if let condition = condition {
            return condition(bytes)
        }
        return true
    }

    func convert(channel: UInt8 = 0) -> ConversionResult {
        return ConversionResult(cc: outputCC, value: outputValue, channel: channel)
    }
}

/// Manages conversion rules and provides default rules
class ConversionRules {
    static let shared = ConversionRules()

    // Default CC numbers (public for Settings UI)
    var ccStart: UInt8 = 80
    var ccStop: UInt8 = 80
    var ccSongPosition: UInt8 = 82
    var ccNextMarker: UInt8 = 83
    var ccPrevMarker: UInt8 = 84

    var defaultChannel: UInt8 = 0

    private init() {}

    /// Get conversion rules for Real-time and System Common messages
    var rules: [ConversionRule] {
        return [
            // Start → CC 80, value 127
            ConversionRule(
                inputStatus: 0xFA,
                outputCC: ccStart,
                outputValue: 127,
                condition: nil
            ),

            // Continue → CC 80, value 127
            ConversionRule(
                inputStatus: 0xFB,
                outputCC: ccStart,
                outputValue: 127,
                condition: nil
            ),

            // Stop → CC 80, value 0
            ConversionRule(
                inputStatus: 0xFC,
                outputCC: ccStop,
                outputValue: 0,
                condition: nil
            ),

            // Song Position (position = 0) → CC 82, value 127
            ConversionRule(
                inputStatus: 0xF2,
                outputCC: ccSongPosition,
                outputValue: 127,
                condition: { bytes in
                    // Song Position Pointer has 3 bytes: status, LSB, MSB
                    guard bytes.count >= 3 else { return false }
                    // Position 0 means both LSB and MSB are 0
                    return bytes[1] == 0 && bytes[2] == 0
                }
            )
        ]
    }

    /// Generate a CC MIDI packet
    func createCCPacket(result: ConversionResult) -> [UInt8] {
        let status: UInt8 = 0xB0 | (result.channel & 0x0F)
        return [status, result.cc, result.value]
    }

    /// Update CC numbers (for future Phase 2 customization)
    func updateCCNumbers(
        start: UInt8? = nil,
        stop: UInt8? = nil,
        songPosition: UInt8? = nil,
        nextMarker: UInt8? = nil,
        prevMarker: UInt8? = nil
    ) {
        if let start = start { ccStart = start }
        if let stop = stop { ccStop = stop }
        if let songPosition = songPosition { ccSongPosition = songPosition }
        if let nextMarker = nextMarker { ccNextMarker = nextMarker }
        if let prevMarker = prevMarker { ccPrevMarker = prevMarker }
    }
}
