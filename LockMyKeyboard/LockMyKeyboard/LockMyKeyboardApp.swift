import AppKit
import SwiftUI

@main
struct LockMyKeyboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Lock My Keyboard", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 440, idealWidth: 480, minHeight: 560, idealHeight: 600)
                .onAppear {
                    appDelegate.model = model
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Lock Keyboard") {
                    model.lock()
                }
                .keyboardShortcut("l", modifiers: [.command])
                .disabled(model.isLocked)

                Button("Unlock Keyboard") {
                    model.unlock()
                }
                .keyboardShortcut("u", modifiers: [.command])
                .disabled(!model.isLocked)
            }
            CommandGroup(replacing: .help) {
                Button("Lock My Keyboard Help") {
                    model.showHelp = true
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.prepareToQuit()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model?.refreshPermissionState()
    }
}
