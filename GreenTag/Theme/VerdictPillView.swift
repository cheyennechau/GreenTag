//
//  VerdictPillView.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/8/26.
//

import SwiftUI

struct VerdictPillView: View {
    let verdict: Verdict

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(verdict.color)
                .frame(width: 6, height: 6)

            Text(verdict.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(verdict.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(verdict.color.opacity(0.12))
        .clipShape(Capsule())
    }
}
