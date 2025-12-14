import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("ccStart") private var ccStart: Int = 80
    @AppStorage("ccStop") private var ccStop: Int = 80
    @AppStorage("ccSongPosition") private var ccSongPosition: Int = 82
    @AppStorage("ccNextMarker") private var ccNextMarker: Int = 83
    @AppStorage("ccPrevMarker") private var ccPrevMarker: Int = 84
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section {
                Text("CC Number Settings")
                    .font(.headline)

                LabeledContent("Start/Continue (CC)") {
                    CCNumberField(value: $ccStart)
                }

                LabeledContent("Stop (CC)") {
                    CCNumberField(value: $ccStop)
                }

                LabeledContent("Song Position Reset (CC)") {
                    CCNumberField(value: $ccSongPosition)
                }

                LabeledContent("Next Marker (CC)") {
                    CCNumberField(value: $ccNextMarker)
                }

                LabeledContent("Previous Marker (CC)") {
                    CCNumberField(value: $ccPrevMarker)
                }

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section {
                Text("Application Settings")
                    .font(.headline)

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
            }

            Section {
                Text("About")
                    .font(.headline)

                LabeledContent("Version") {
                    Text("1.0.0 (Phase 2)")
                }

                LabeledContent("Description") {
                    Text("Converts MIDI Real-time messages to CC")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
        .onChange(of: ccStart) { _, newValue in
            ConversionRules.shared.ccStart = UInt8(newValue)
        }
        .onChange(of: ccStop) { _, newValue in
            ConversionRules.shared.ccStop = UInt8(newValue)
        }
        .onChange(of: ccSongPosition) { _, newValue in
            ConversionRules.shared.ccSongPosition = UInt8(newValue)
        }
        .onChange(of: ccNextMarker) { _, newValue in
            ConversionRules.shared.ccNextMarker = UInt8(newValue)
        }
        .onChange(of: ccPrevMarker) { _, newValue in
            ConversionRules.shared.ccPrevMarker = UInt8(newValue)
        }
    }

    private func resetToDefaults() {
        ccStart = 80
        ccStop = 80
        ccSongPosition = 82
        ccNextMarker = 83
        ccPrevMarker = 84
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}

struct CCNumberField: View {
    @Binding var value: Int
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    init(value: Binding<Int>) {
        self._value = value
        self._textValue = State(initialValue: "\(value.wrappedValue)")
    }

    var body: some View {
        TextField("", text: $textValue)
            .focused($isFocused)
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)
            .multilineTextAlignment(.trailing)
            .onChange(of: textValue) { _, newValue in
                if let intValue = Int(newValue), intValue >= 0, intValue <= 127 {
                    value = intValue
                }
            }
            .onChange(of: value) { _, newValue in
                if !isFocused {
                    textValue = "\(newValue)"
                }
            }
            .onSubmit {
                validateAndUpdate()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
            )
    }

    private var isValid: Bool {
        guard let intValue = Int(textValue) else { return false }
        return intValue >= 0 && intValue <= 127
    }

    private func validateAndUpdate() {
        if let intValue = Int(textValue), intValue >= 0, intValue <= 127 {
            value = intValue
        } else {
            textValue = "\(value)"
        }
    }
}

#Preview {
    SettingsView()
}
