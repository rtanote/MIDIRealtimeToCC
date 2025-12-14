//
//  main.swift
//  MIDIRealtimeToCC
//
//  Main entry point for the CLI application
//

import Foundation
import CoreMIDI

// MARK: - Main Application

class Application {
    private let midiManager = MIDIManager()
    private let messageProcessor = MessageProcessor()
    private let parser = CommandLineParser()

    private var isRunning = false

    func run() {
        // Setup signal handling for Ctrl+C
        setupSignalHandler()

        do {
            let option = try parser.parse()

            switch option {
            case .help:
                parser.printHelp()
                exit(0)

            case .version:
                parser.printVersion()
                exit(0)

            case .list:
                try handleListDevices()
                exit(0)

            case .run(let inputDevice, let outputDevice):
                try handleRun(inputDevice: inputDevice, outputDevice: outputDevice)
            }
        } catch {
            printError("\(error)")
            exit(1)
        }
    }

    private func handleListDevices() throws {
        try midiManager.initialize()

        let inputs = midiManager.getInputDevices().map { $0.displayName }
        let outputs = midiManager.getOutputDevices().map { $0.displayName }

        parser.printDeviceList(inputs: inputs, outputs: outputs)
    }

    private func handleRun(inputDevice: String, outputDevice: String) throws {
        // Print header
        printHeader()

        // Initialize MIDI
        try midiManager.initialize()

        // Setup callbacks
        setupCallbacks()

        // Connect devices
        print("Input:  \(inputDevice)")
        try midiManager.connectInput(deviceName: inputDevice)

        print("Output: \(outputDevice)")
        try midiManager.connectOutput(deviceName: outputDevice)

        print("\nListening... (Press Ctrl+C to quit)\n")

        // Run main loop
        isRunning = true
        runMainLoop()
    }

    private func setupCallbacks() {
        // MIDI Manager → Message Processor
        midiManager.onReceiveMessage = { [weak self] bytes in
            self?.messageProcessor.processMessage(bytes)
        }

        // Message Processor → MIDI Manager (converted messages)
        messageProcessor.onConvertedMessage = { [weak self] bytes in
            self?.midiManager.sendMessage(bytes)
        }

        // Message Processor → MIDI Manager (pass-through messages)
        messageProcessor.onPassThroughMessage = { [weak self] bytes in
            self?.midiManager.sendMessage(bytes)
        }

        // Logging
        let timestamp: () -> String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: Date())
        }

        midiManager.onLog = { message in
            // Only log errors and important events, not every message
            if message.contains("error") || message.contains("Error") ||
               message.contains("Failed") || message.contains("failed") {
                print("[\(timestamp())] \(message)")
            }
        }

        messageProcessor.onLog = { message in
            print("[\(timestamp())] \(message)")
        }
    }

    private func runMainLoop() {
        // Run the main run loop
        while isRunning {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }

        // Cleanup
        midiManager.cleanup()
        print("\nShutdown complete.")
    }

    private func setupSignalHandler() {
        signal(SIGINT) { signal in
            print("\n\nReceived interrupt signal. Shutting down...")
            // Get the shared application instance via global variable
            sharedApp?.isRunning = false
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    private func printHeader() {
        print("MIDIRealtimeToCC v0.1.0")
    }

    private func printError(_ message: String) {
        let stderr = FileHandle.standardError
        if let data = "Error: \(message)\n".data(using: .utf8) {
            stderr.write(data)
        }
    }
}

// MARK: - Entry Point

// Global reference for signal handler
var sharedApp: Application?

// Create and run application
let app = Application()
sharedApp = app
app.run()
