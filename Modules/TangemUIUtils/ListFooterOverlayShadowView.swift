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

    public init(color: Color = Colors.Background.primary, opacities: [CGFloat] = [0.0, 0.95]) {
        colors = opacities.map { color.opacity($0) }
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
