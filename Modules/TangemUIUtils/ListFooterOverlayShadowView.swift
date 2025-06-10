//
//  ListFooterOverlayShadowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct ListFooterOverlayShadowView: View {
    private let colors: [Color]

    public init(colors: [Color] = [Colors.Background.primary.opacity(0.0), Colors.Background.primary.opacity(0.95)]) {
        self.colors = colors
    }

    public var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .bottom)
    }
}
