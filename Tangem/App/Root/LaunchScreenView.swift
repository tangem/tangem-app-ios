//
//  LaunchScreenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct LaunchScreenView: View {
    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LaunchScreenView()
}
