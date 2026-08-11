import SwiftUI

@main
struct LockMyKeyboardApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Lock My Keyboard", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 420, idealWidth: 460, minHeight: 520, idealHeight: 560)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
