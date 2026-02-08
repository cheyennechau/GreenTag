import SwiftUI

@main
struct GreenTagApp: App {
    @StateObject private var scanStore = ScanStore()

    var body: some Scene {
            WindowGroup {
                RootView()
                    .environmentObject(scanStore)
            }
        }
}
