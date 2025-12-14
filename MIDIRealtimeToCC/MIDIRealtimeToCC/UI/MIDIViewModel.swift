import SwiftUI
import Combine

class MIDIViewModel: ObservableObject {
    @Published var inputDevices: [String] = []
    @Published var outputDevices: [String] = []
    @Published var selectedInputDevice: String? {
        didSet {
            if let device = selectedInputDevice {
                UserDefaults.standard.set(device, forKey: "inputDevice")
                connectDevices()
            }
        }
    }
    @Published var selectedOutputDevice: String? {
        didSet {
            if let device = selectedOutputDevice {
                UserDefaults.standard.set(device, forKey: "outputDevice")
                connectDevices()
            }
        }
    }
    @Published var isEnabled: Bool = true {
        didSet {
            messageProcessor.isEnabled = isEnabled
            UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
        }
    }
    @Published var isConnected: Bool = false
    @Published var lastActivity: String?

    private let midiManager = MIDIManager()
    private let messageProcessor = MessageProcessor()
    private var deviceListUpdateTimer: Timer?

    init() {
        setupMIDI()
        loadSettings()
        updateDeviceList()

        // Update device list every 2 seconds for hot-plugging support
        deviceListUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDeviceList()
        }
    }

    deinit {
        deviceListUpdateTimer?.invalidate()
    }

    private func setupMIDI() {
        do {
            try midiManager.initialize()

            // Setup callbacks
            midiManager.onReceiveMessage = { [weak self] bytes in
                self?.messageProcessor.processMessage(bytes)
            }

            messageProcessor.onConvertedMessage = { [weak self] bytes in
                self?.midiManager.sendMessage(bytes)
            }

            messageProcessor.onPassThroughMessage = { [weak self] bytes in
                self?.midiManager.sendMessage(bytes)
            }

            messageProcessor.onLog = { [weak self] message in
                DispatchQueue.main.async {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm:ss"
                    let timestamp = dateFormatter.string(from: Date())
                    self?.lastActivity = "[\(timestamp)] \(message)"
                }
            }
        } catch {
            print("Failed to initialize MIDI: \(error)")
        }
    }

    private func loadSettings() {
        selectedInputDevice = UserDefaults.standard.string(forKey: "inputDevice")
        selectedOutputDevice = UserDefaults.standard.string(forKey: "outputDevice")
        isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")

        // Load CC settings
        let rules = ConversionRules.shared
        if let ccStart = UserDefaults.standard.object(forKey: "ccStart") as? Int {
            rules.ccStart = UInt8(ccStart)
        }
        if let ccStop = UserDefaults.standard.object(forKey: "ccStop") as? Int {
            rules.ccStop = UInt8(ccStop)
        }
        if let ccSongPosition = UserDefaults.standard.object(forKey: "ccSongPosition") as? Int {
            rules.ccSongPosition = UInt8(ccSongPosition)
        }
        if let ccNextMarker = UserDefaults.standard.object(forKey: "ccNextMarker") as? Int {
            rules.ccNextMarker = UInt8(ccNextMarker)
        }
        if let ccPrevMarker = UserDefaults.standard.object(forKey: "ccPrevMarker") as? Int {
            rules.ccPrevMarker = UInt8(ccPrevMarker)
        }
    }

    private func updateDeviceList() {
        let (inputs, outputs) = midiManager.listDevices()

        DispatchQueue.main.async { [weak self] in
            self?.inputDevices = inputs
            self?.outputDevices = outputs
        }
    }

    private func connectDevices() {
        guard let inputName = selectedInputDevice,
              let outputName = selectedOutputDevice else {
            isConnected = false
            return
        }

        do {
            try midiManager.connectToInput(name: inputName)
            try midiManager.connectToOutput(name: outputName)
            isConnected = true
        } catch {
            print("Connection error: \(error)")
            isConnected = false
        }
    }
}
