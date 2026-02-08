//
//  RootView.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        #if CHEYENNE
        CheyenneRootView()
        #else
        BiaRootView()
        #endif
    }
}

#Preview {
    RootView()
}
