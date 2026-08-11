import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("How to use")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    step(number: "1", title: "Allow Accessibility", body: "macOS asks once. Lock My Keyboard uses this only to block keys while Locked — never to read or store what you type.")
                    step(number: "2", title: "Click Lock", body: "Keyboard input is suppressed. Trackpad and mouse keep working so you can click Unlock.")
                    step(number: "3", title: "Clean the keyboard", body: "Wipe dust and fingerprints. Shortcuts and typing will not reach other apps.")
                    step(number: "4", title: "Click Unlock", body: "Typing returns immediately. Quitting the app also unlocks (fail-open).")

                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If something goes wrong")
                                .font(.headline)
                            Text("• Force-quit from Activity Monitor — the lock ends with the process.\n• Restart your Mac if the app is unresponsive.\n• Re-enable the app under System Settings → Privacy & Security → Accessibility.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 460)
    }

    private func step(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Theme.lockButton, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
