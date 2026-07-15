//
//  TangemPayCardPageIndicatorRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayCardPageIndicatorRedesigned: View {
    let count: Int
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< count, id: \.self) { index in
                Circle()
                    .fill(DesignSystem.Color.iconPrimary)
                    .opacity(index == selectedIndex ? 1 : 0.32)
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        TangemPayCardPageIndicatorRedesigned(count: 2, selectedIndex: 1)
        TangemPayCardPageIndicatorRedesigned(count: 3, selectedIndex: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
