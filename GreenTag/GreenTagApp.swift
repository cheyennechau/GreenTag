import SwiftUI

@main
struct GreenTagApp: App {
    // <- add this StateObject so `scanStore` exists in scope
    @StateObject private var scanStore = ScanStore()

    var body: some Scene {
            WindowGroup {
                // Use HomeView as the single root so navigation and environmentObject are consistent
                HomeView()
                    .environmentObject(scanStore)
                    .task {
                        // async load persisted data, then seed if empty
                        await scanStore.loadIfNeeded()
                    }
            }
        }
}
