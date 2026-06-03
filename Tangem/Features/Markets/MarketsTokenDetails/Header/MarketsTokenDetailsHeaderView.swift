//
//  MarketsTokenDetailsHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MarketsTokenDetailsHeaderView: View {
    let tokenName: String
    let tokenSymbol: String
    let price: AttributedString?
    let priceDate: String
    let priceChangeState: PriceChangeView.State?
    let priceChangeAnimation: Published<ForegroundBlinkAnimationChange>.Publisher
    let iconURL: URL

    @ScaledMetric private var verticalSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var horizontalMinSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var nameSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var priceSpacing: CGFloat = .unit(.x1_5)
    @ScaledSize private var iconSize: CGSize = .init(bothDimensions: 70)

    var body: some View {
        HStack(alignment: .top, spacing: .zero) {
            VStack(alignment: .leading, spacing: verticalSpacing) {
                nameView

                if let price {
                    priceView(price)
                }

                priceChangeView
            }

            Spacer(minLength: horizontalMinSpacing)

            IconView(url: iconURL, size: iconSize, forceKingfisher: true)
        }
    }
}

// MARK: - Subviews

private extension MarketsTokenDetailsHeaderView {
    var nameView: some View {
        HStack(alignment: .lastTextBaseline, spacing: nameSpacing) {
            Text(tokenName)
                .style(.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)

            Text(tokenSymbol)
                .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.tertiary)
        }
        .lineLimit(1)
    }

    func priceView(_ price: AttributedString) -> some View {
        ZStack {
            // This `Text` view acts as an invisible container, maintaining constant height
            // to prevent UI from jumping when the font of the price label is scaled down
            Text(Constants.priceStubText)
                .style(.Tangem.Custom.titleRegular44, color: .Tangem.Text.Neutral.primary)
                .opacity(.zero)
                .accessibilityHidden(true)

            AttributedStringBlinkAnimationView(
                originalString: price,
                publisher: priceChangeAnimation,
                positiveColor: .Tangem.Text.Status.accent,
                negativeColor: .Tangem.Text.Status.warning,
                duration: 0.5
            )
            .minimumScaleFactor(0.5)
            .infinityFrame(axis: .horizontal, alignment: .leading)
        }
        .lineLimit(1)
        .truncationMode(.middle)
    }

    var priceChangeView: some View {
        HStack(alignment: .firstTextBaseline, spacing: priceSpacing) {
            Text(priceDate)
                .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.primary)

            if let priceChangeState {
                PriceChangeView(
                    state: priceChangeState,
                    showSkeletonWhenLoading: true,
                    useRedesignColors: true
                )
                .animation(.none, value: priceDate)
            }
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsHeaderView {
    enum Constants {
        static let priceStubText = "1234.0"
    }
}
