//
//  MarketsNavigationBarTitle.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsNavigationBarTitle: View {
    struct State: Equatable {
        let priceOpacity: CGFloat?
        let titleOffset: CGFloat
    }

    let tokenName: String
    let price: String?

    let state: State
    let spacing: CGFloat
    let fadesOverflow: Bool

    init(tokenName: String, price: String?, state: State, spacing: CGFloat = 0, fadesOverflow: Bool = false) {
        self.tokenName = tokenName
        self.price = price
        self.state = state
        self.spacing = spacing
        self.fadesOverflow = fadesOverflow
    }

    var body: some View {
        VStack(spacing: spacing) {
            title
                .animation(animation, value: state.titleOffset)

            if let price {
                pricePlaceholder(price)
                    .overlay {
                        if let opacity = state.priceOpacity {
                            priceText(price)
                                .opacity(opacity)
                                .animation(.default, value: state.priceOpacity)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        if fadesOverflow {
            ViewThatFits(in: .horizontal) {
                tokenNameText

                tokenNameText
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .reverseMask(alignment: .trailing) {
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 24)
                    }
            }
        } else {
            tokenNameText
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        }
    }

    private var tokenNameText: some View {
        Text(tokenName)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .fixedSize(horizontal: fadesOverflow, vertical: false)
    }

    private func pricePlaceholder(_ text: String) -> some View {
        priceText(text)
            .opacity(0)
            .frame(height: state.titleOffset)
            .animation(animation, value: state.titleOffset)
    }

    private func priceText(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
    }

    private var animation: Animation {
        .easeIn(duration: 0.15) // reduced to minimize animation lag on fast scrolling
    }
}
