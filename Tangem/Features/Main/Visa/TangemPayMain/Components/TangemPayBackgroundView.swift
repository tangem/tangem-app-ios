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
    var textureOpacity: CGFloat = 1

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Color.bgPrimary
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
                .opacity(textureOpacity)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }
}
