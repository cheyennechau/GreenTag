//
//  ScanScreen.swift
//  GreenTag
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

struct ScanScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color("4CAF50"))
            Text("Scan a Tag")
                .font(.title).bold()
            Text("Camera scanning screen placeholder. Implement scanning here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Scan")
    }
}

#Preview {
    NavigationStack { ScanScreen() }
}
