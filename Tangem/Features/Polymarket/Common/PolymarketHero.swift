//
//  PolymarketHero.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct PolymarketHero: View {
    let image: ImageType
    let tint: Tint
    let scrollSpace: String

    var body: some View {
        Color.clear
            .aspectRatio(Constants.uncoveredAspectRatio, contentMode: .fit)
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    let overscroll = max(0, proxy.frame(in: .named(scrollSpace)).minY)

                    image.image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.width / Constants.aspectRatio + overscroll)
                        .clipped()
                        .overlay { gradient }
                        .offset(y: -overscroll)
                }
            }
            .accessibilityHidden(true)
    }

    private var gradient: some View {
        LinearGradient(
            stops: [
                .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: tint.start),
                .init(color: DesignSystem.Color.bgPrimary, location: tint.end),
                .init(color: DesignSystem.Color.bgPrimary, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Tint

extension PolymarketHero {
    struct Tint {
        let start: CGFloat
        let end: CGFloat
    }
}

// MARK: - Constants

private extension PolymarketHero {
    enum Constants {
        static let aspectRatio: CGFloat = 402.0 / 608.0
        static let uncoveredAspectRatio: CGFloat = 402.0 / 495.0
    }
}
