import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                Text("Lock My Keyboard")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.14, blue: 0.18))

                KeyboardArt(isLocked: model.isLocked)
                    .frame(height: 180)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button(action: model.primaryAction) {
                        Text(model.primaryButtonTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(model.isLocked ? Color(red: 0.16, green: 0.45, blue: 0.38) : Color(red: 0.18, green: 0.22, blue: 0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 40)

                    Text(model.statusText)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(red: 0.35, green: 0.38, blue: 0.42))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .frame(minHeight: 36)

                    if case .needsPermission = model.uiState {
                        Button("Open Accessibility Settings", action: model.openAccessibilitySettings)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 36)
            .padding(.bottom, 28)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refreshPermissionState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            model.prepareToQuit()
        }
        .background(WindowAccessor(isLocked: model.isLocked))
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.95, blue: 0.97),
                Color(red: 0.86, green: 0.90, blue: 0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// Keeps the window reachable while locked so Unlock stays clickable.
private struct WindowAccessor: NSViewRepresentable {
    let isLocked: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { updateLevel(for: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { updateLevel(for: nsView) }
    }

    private func updateLevel(for view: NSView) {
        guard let window = view.window else { return }
        window.level = isLocked ? .floating : .normal
    }
}
