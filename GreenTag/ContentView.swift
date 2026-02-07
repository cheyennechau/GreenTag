import SwiftUI

struct ContentView: View {
    @State private var screenState: ScreenState = .scan

    var body: some View {
        NavigationStack {
            Group {
                switch screenState {
                case .scan:
                    ScanView(screenState: $screenState)
                case .loading:
                    LoadingView(screenState: $screenState)
                case .error:
                    ErrorView(screenState: $screenState)
                case .results:
                    ResultsView(
                        result: SampleData.result,
                        screenState: $screenState
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: screenState)
        }
    }
}

#Preview {
    ContentView()
}
