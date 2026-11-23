//
//  MarketsPortfolioTokenBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsPortfolioTokenBalanceView: View {
    @ScaledMetric private var failedBalanceTextIconSpacing: CGFloat = 2
    @ScaledMetric private var failedBalanceIconSide: CGFloat = 16

    let state: MarketsPortfolioTokenBalanceState
    let skeletonSize: CGSize
    let token: TangemTypographyToken
    let color: Color

    @ObservedObject private var visibilityState = SensitiveTextVisibilityState.shared

    var body: some View {
        switch state {
        case .loaded(let text):
            textView(text)

        case .loadingCached(let text):
            textView(text)
                .shimmering()

        case .loading:
            skeletonView(size: skeletonSize)
                .shimmering()

        case .failed(let text, .none):
            textView(text)

        case .failed(let text, .some(let icon)):
            let image = icon.type.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(icon.color)
                .frame(width: failedBalanceIconSide, height: failedBalanceIconSide)

            HStack(spacing: failedBalanceTextIconSpacing) {
                if icon.location == .leading {
                    image
                }

                textView(text)

                if icon.location == .trailing {
                    image
                }
            }
        }
    }
}

// MARK: - Subviews

private extension MarketsPortfolioTokenBalanceView {
    func textView(_ text: MarketsPortfolioTokenBalanceState.Text) -> some View {
        UtilBalance(text)
            .masked(visibilityState.isHidden)
            .style(token, color: color)
    }

    func skeletonView(size: CGSize) -> some View {
        Capsule(style: .continuous)
            .fill(DesignSystem.Color.bgTransparentSecondary)
            .frame(size: size)
    }
}
