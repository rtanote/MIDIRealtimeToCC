//
//  CommandLineParser.swift
//  MIDIRealtimeToCC
//
//  Parses command-line arguments and provides CLI interface
//

import Foundation

/// Command-line options
enum CLIOption {
    case list
    case help
    case version
    case run(input: String, output: String)
}

/// Parses and validates command-line arguments
class CommandLineParser {
    private let arguments: [String]
    private let version = "0.1.0"

    init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    /// Parse command-line arguments
    func parse() throws -> CLIOption {
        // Skip first argument (program name)
        let args = Array(arguments.dropFirst())

        guard !args.isEmpty else {
            throw CLIError.missingArguments
        }

        // Check for flags
        if args.contains("--help") || args.contains("-h") {
            return .help
        }

        if args.contains("--version") || args.contains("-v") {
            return .version
        }

        if args.contains("--list") || args.contains("-l") {
            return .list
        }

        // Parse input/output arguments
        let inputDevice = try getValue(for: "--input", in: args)
        let outputDevice = try getValue(for: "--output", in: args)

        return .run(input: inputDevice, output: outputDevice)
    }

    /// Print help message
    func printHelp() {
        print("""
        MIDIRealtimeToCC v\(version)

        DESCRIPTION:
            Converts MIDI Real-time messages to Control Change (CC) messages.
            Enables DAW transport control from MIDI controller sequencer buttons.

        USAGE:
            MIDIRealtimeToCC [options]

        OPTIONS:
            --list, -l              List available MIDI devices
            --input <name>          Specify input device name
            --output <name>         Specify output device name
            --help, -h              Show this help message
            --version, -v           Show version information

        EXAMPLES:
            # List all MIDI devices
            MIDIRealtimeToCC --list

            # Start conversion
            MIDIRealtimeToCC --input "Roland A-70" --output "IAC Driver Bus 1"

        CONVERSION TABLE:
            Start (0xFA)        → CC 80, value 127
            Continue (0xFB)     → CC 80, value 127
            Stop (0xFC)         → CC 80, value 0
            Song Pos 0 (0xF2)   → CC 82, value 127
            Song Select Inc     → CC 83, value 127
            Song Select Dec     → CC 84, value 127

        For more information, visit:
        https://github.com/yourusername/MIDIRealtimeToCC
        """)
    }

    /// Print version information
    func printVersion() {
        print("MIDIRealtimeToCC v\(version)")
    }

    /// Print device list
    func printDeviceList(inputs: [String], outputs: [String]) {
        print("MIDIRealtimeToCC v\(version)\n")

        print("MIDI Input Devices:")
        if inputs.isEmpty {
            print("  (none)")
        } else {
            for (index, name) in inputs.enumerated() {
                print("  [\(index + 1)] \(name)")
            }
        }

        print("\nMIDI Output Devices:")
        if outputs.isEmpty {
            print("  (none)")
        } else {
            for (index, name) in outputs.enumerated() {
                print("  [\(index + 1)] \(name)")
            }
        }

        print("\nUsage:")
        print("  MIDIRealtimeToCC --input \"<device name>\" --output \"<device name>\"")
    }

    // MARK: - Private Helpers

    private func getValue(for flag: String, in args: [String]) throws -> String {
        guard let index = args.firstIndex(of: flag) else {
            throw CLIError.missingFlag(flag)
        }

        let valueIndex = index + 1
        guard valueIndex < args.count else {
            throw CLIError.missingValue(flag)
        }

        let value = args[valueIndex]
        guard !value.hasPrefix("--") else {
            throw CLIError.missingValue(flag)
        }

        return value
    }
}

// MARK: - Error Types

enum CLIError: Error, CustomStringConvertible {
    case missingArguments
    case missingFlag(String)
    case missingValue(String)
    case invalidArgument(String)

    var description: String {
        switch self {
        case .missingArguments:
            return "Missing arguments. Use --help for usage information."
        case .missingFlag(let flag):
            return "Missing required flag: \(flag)"
        case .missingValue(let flag):
            return "Missing value for flag: \(flag)"
        case .invalidArgument(let arg):
            return "Invalid argument: \(arg)"
        }
    }
}
