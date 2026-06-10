//
//  TangemPayBackgroundView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayBackgroundView: View {
    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Tokens.Theme.Bg.primary
                .ignoresSafeArea()

            Assets.Visa.paymentAccountBackground.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .mask(alignment: .top) {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.75),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }
}
