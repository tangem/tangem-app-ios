//
//  MarketsPortfolioTokenBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsPortfolioTokenBalanceView: View {
    @ScaledMetric private var failedBalanceTextIconSpacing: CGFloat = .unit(.half)
    @ScaledMetric private var failedBalanceIconSide = CGFloat.unit(.x4)

    let state: MarketsPortfolioTokenBalanceState
    let skeletonSize: CGSize

    var body: some View {
        switch state {
        case .loaded(let text):
            textView(text)

        case .loadingCached(let text):
            textView(text)
                .shimmer()

        case .loading:
            skeletonView(size: skeletonSize)
                .shimmer()

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
        SensitiveText(text)
    }

    func skeletonView(size: CGSize) -> some View {
        Capsule(style: .continuous)
            .fill(Color.Tangem.Skeleton.backgroundPrimary)
            .frame(size: size)
    }
}
