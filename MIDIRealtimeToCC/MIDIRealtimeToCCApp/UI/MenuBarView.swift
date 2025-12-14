import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = MIDIViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.headline)
            }

            Divider()

            // Input Device Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Input Device")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $viewModel.selectedInputDevice) {
                    Text("None").tag(nil as String?)
                    ForEach(viewModel.inputDevices, id: \.self) { device in
                        Text(device).tag(device as String?)
                    }
                }
                .labelsHidden()
                .frame(width: 250)
            }

            // Output Device Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Output Device")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $viewModel.selectedOutputDevice) {
                    Text("None").tag(nil as String?)
                    ForEach(viewModel.outputDevices, id: \.self) { device in
                        Text(device).tag(device as String?)
                    }
                }
                .labelsHidden()
                .frame(width: 250)
            }

            Divider()

            // Enable/Disable Toggle
            Toggle("Enable Conversion", isOn: $viewModel.isEnabled)

            Divider()

            // Activity Log
            if let lastActivity = viewModel.lastActivity {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastActivity)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }

            Divider()

            // Settings Button
            SettingsLink {
                Text("Settings...")
            }

            // Quit Button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    MenuBarView()
}
