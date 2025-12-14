//
//  MIDIManager.swift
//  MIDIRealtimeToCC
//
//  Manages CoreMIDI connections and device enumeration
//

import Foundation
import CoreMIDI

/// Represents a MIDI device
struct MIDIDevice {
    let name: String
    let uniqueID: Int32
    let endpoint: MIDIEndpointRef
    let isSource: Bool

    var displayName: String {
        return name
    }
}

/// Manages MIDI client, ports, and device connections
class MIDIManager {
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var outputPort: MIDIPortRef = 0

    private var connectedInputSource: MIDIEndpointRef?
    private var connectedOutputDestination: MIDIEndpointRef?

    var onReceiveMessage: (([UInt8]) -> Void)?
    var onLog: ((String) -> Void)?

    private var isInitialized = false

    init() {}

    /// Initialize MIDI client and ports
    func initialize() throws {
        guard !isInitialized else { return }

        var status: OSStatus

        // Create MIDI client
        status = MIDIClientCreateWithBlock("MIDIRealtimeToCC" as CFString, &client) { notification in
            self.handleNotification(notification)
        }
        guard status == noErr else {
            throw MIDIError.clientCreationFailed(status)
        }

        // Create input port
        status = MIDIInputPortCreateWithBlock(
            client,
            "Input" as CFString,
            &inputPort
        ) { packetList, srcConnRefCon in
            self.handlePacketList(packetList)
        }
        guard status == noErr else {
            throw MIDIError.portCreationFailed(status)
        }

        // Create output port
        status = MIDIOutputPortCreate(client, "Output" as CFString, &outputPort)
        guard status == noErr else {
            throw MIDIError.portCreationFailed(status)
        }

        isInitialized = true
        onLog?("MIDI client initialized")
    }

    /// Get all available MIDI input sources
    func getInputDevices() -> [MIDIDevice] {
        let count = MIDIGetNumberOfSources()
        var devices: [MIDIDevice] = []

        for i in 0..<count {
            let endpoint = MIDIGetSource(i)
            if let device = createDevice(from: endpoint, isSource: true) {
                devices.append(device)
            }
        }

        return devices
    }

    /// Get all available MIDI output destinations
    func getOutputDevices() -> [MIDIDevice] {
        let count = MIDIGetNumberOfDestinations()
        var devices: [MIDIDevice] = []

        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            if let device = createDevice(from: endpoint, isSource: false) {
                devices.append(device)
            }
        }

        return devices
    }

    /// Connect to an input device by name
    func connectInput(deviceName: String) throws {
        guard isInitialized else {
            throw MIDIError.notInitialized
        }

        let devices = getInputDevices()
        guard let device = devices.first(where: { $0.name == deviceName }) else {
            throw MIDIError.deviceNotFound(deviceName)
        }

        // Disconnect previous if exists
        if let previous = connectedInputSource {
            MIDIPortDisconnectSource(inputPort, previous)
        }

        // Connect to new source
        let status = MIDIPortConnectSource(inputPort, device.endpoint, nil)
        guard status == noErr else {
            throw MIDIError.connectionFailed(status)
        }

        connectedInputSource = device.endpoint
        onLog?("Connected to input: \(device.name)")
    }

    /// Connect to an output device by name
    func connectOutput(deviceName: String) throws {
        guard isInitialized else {
            throw MIDIError.notInitialized
        }

        let devices = getOutputDevices()
        guard let device = devices.first(where: { $0.name == deviceName }) else {
            throw MIDIError.deviceNotFound(deviceName)
        }

        connectedOutputDestination = device.endpoint
        onLog?("Connected to output: \(device.name)")
    }

    /// Send MIDI message bytes to the connected output device
    func sendMessage(_ bytes: [UInt8]) {
        guard let destination = connectedOutputDestination else { return }
        guard !bytes.isEmpty else { return }

        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)

        let timestamp = mach_absolute_time()
        packet = MIDIPacketListAdd(
            &packetList,
            1024,
            packet,
            timestamp,
            bytes.count,
            bytes
        )

        guard packet != nil else {
            onLog?("Failed to create MIDI packet")
            return
        }

        let status = MIDISend(outputPort, destination, &packetList)
        if status != noErr {
            onLog?("Failed to send MIDI message: \(status)")
        }
    }

    /// Disconnect all devices and cleanup
    func cleanup() {
        if let source = connectedInputSource {
            MIDIPortDisconnectSource(inputPort, source)
            connectedInputSource = nil
        }

        connectedOutputDestination = nil

        if inputPort != 0 {
            MIDIPortDispose(inputPort)
            inputPort = 0
        }

        if outputPort != 0 {
            MIDIPortDispose(outputPort)
            outputPort = 0
        }

        if client != 0 {
            MIDIClientDispose(client)
            client = 0
        }

        isInitialized = false
        onLog?("MIDI cleanup completed")
    }

    // MARK: - Private Helpers

    private func createDevice(from endpoint: MIDIEndpointRef, isSource: Bool) -> MIDIDevice? {
        var name: Unmanaged<CFString>?
        var uniqueID: Int32 = 0

        // Get device name
        var status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        guard status == noErr, let deviceName = name?.takeRetainedValue() as String? else {
            return nil
        }

        // Get unique ID
        status = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        guard status == noErr else {
            return nil
        }

        return MIDIDevice(
            name: deviceName,
            uniqueID: uniqueID,
            endpoint: endpoint,
            isSource: isSource
        )
    }

    private func handlePacketList(_ packetList: UnsafePointer<MIDIPacketList>) {
        let packets = packetList.pointee
        var packet = packets.packet

        for _ in 0..<packets.numPackets {
            let bytes = extractBytes(from: packet)
            if !bytes.isEmpty {
                onReceiveMessage?(bytes)
            }

            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private func extractBytes(from packet: MIDIPacket) -> [UInt8] {
        let length = Int(packet.length)
        guard length > 0 else { return [] }

        return withUnsafeBytes(of: packet.data) { ptr in
            Array(ptr.prefix(length))
        }
    }

    private func handleNotification(_ notification: UnsafePointer<MIDINotification>) {
        let notif = notification.pointee

        switch notif.messageID {
        case .msgSetupChanged:
            onLog?("MIDI setup changed")

        case .msgObjectAdded:
            onLog?("MIDI object added")

        case .msgObjectRemoved:
            onLog?("MIDI object removed")

        case .msgPropertyChanged:
            onLog?("MIDI property changed")

        default:
            break
        }
    }
}

// MARK: - Error Types

enum MIDIError: Error, CustomStringConvertible {
    case notInitialized
    case clientCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
    case deviceNotFound(String)
    case connectionFailed(OSStatus)

    var description: String {
        switch self {
        case .notInitialized:
            return "MIDI client not initialized"
        case .clientCreationFailed(let status):
            return "Failed to create MIDI client: \(status)"
        case .portCreationFailed(let status):
            return "Failed to create MIDI port: \(status)"
        case .deviceNotFound(let name):
            return "MIDI device not found: \(name)"
        case .connectionFailed(let status):
            return "Failed to connect to device: \(status)"
        }
    }
}
