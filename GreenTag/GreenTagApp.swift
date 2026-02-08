import SwiftUI

@main
struct GreenTagApp: App {
    // <- add this StateObject so `scanStore` exists in scope
    @StateObject private var scanStore = ScanStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanStore) // inject the single shared store
                .onAppear {
                    // quick debug so you can see the store path in console
                    #if DEBUG
                    print("[GreenTagApp] ScanStore injected")
                    #endif
                }
        }
    }
}
