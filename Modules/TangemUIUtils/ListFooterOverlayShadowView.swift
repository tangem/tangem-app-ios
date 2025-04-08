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
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [
                Colors.Background.primary.opacity(0.0),
                Colors.Background.primary.opacity(0.95),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .bottom)
    }
}
