import SwiftUI

@main
struct SonyHeadphonesApp: App {
    @State private var manager = HeadphonesManager()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(manager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: manager.isConnected ? "headphones" : "headphones.circle")
                if !manager.menuBarBatteryText.isEmpty {
                    Text(manager.menuBarBatteryText)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
