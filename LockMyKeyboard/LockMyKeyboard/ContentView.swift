import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                header

                KeyboardArt(isLocked: model.isLocked)
                    .frame(height: 190)
                    .padding(.horizontal, 28)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.isLocked)

                controls

                Spacer(minLength: 8)

                footer
            }
            .padding(.top, 32)
            .padding(.bottom, 20)
        }
        .onChange(of: model.isLocked) { _, locked in
            // Window level updates via accessor.
            _ = locked
        }
        .sheet(isPresented: $model.showHelp) {
            HelpView()
        }
        .background(WindowAccessor(isLocked: model.isLocked))
        .onAppear { model.refreshPermissionState() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Lock My Keyboard")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.brand)

            Text("Clean without accidental typing")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.brandMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: model.primaryAction) {
                HStack(spacing: 10) {
                    if model.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(model.isBusy ? (model.isLocked ? "Unlocking…" : "Locking…") : model.primaryButtonTitle)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(model.isLocked ? Theme.unlockButton : Theme.lockButton)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 44)
            .disabled(model.isBusy)
            .opacity(model.isBusy ? 0.85 : 1)
            .accessibilityLabel(model.primaryButtonTitle)
            .accessibilityHint(model.primaryButtonAccessibilityHint)
            .accessibilityValue(model.isBusy ? "In progress" : "")

            Text(model.statusText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(statusColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .frame(minHeight: 40)
                .accessibilityAddTraits(.updatesFrequently)

            if case .needsPermission = model.uiState {
                Button("Open Accessibility Settings", action: model.openAccessibilitySettings)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .disabled(model.isBusy)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button("Help") { model.showHelp = true }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.brandMuted)

            Text("Pointer stays active · No keystroke logging")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.brandMuted.opacity(0.9))
        }
    }

    private var statusColor: Color {
        switch model.uiState {
        case .error: return Theme.dangerSoft
        case .needsPermission: return Theme.warningSoft
        default: return Theme.brandMuted
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Theme.surfaceTop, Theme.surfaceBottom],
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
        window.collectionBehavior.insert(.moveToActiveSpace)
    }
}
