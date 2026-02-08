//
//  BiaRootView.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import SwiftUI

struct BiaRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("GreenTag")
                    .font(.largeTitle)
                    .bold()

                Text("Welcome")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    BiaRootView()
}
