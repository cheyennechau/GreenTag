import SwiftUI

struct BrandSearchView: View {
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section("Suggestions") {
                        Text("Try searching for a brand like Patagonia, Levi's, or H&M")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Results") {
                        Text("No results for \"\(query)\" yet.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search brands")
            .navigationTitle("Search Brands")
        }
    }
}

#Preview {
    BrandSearchView()
}
