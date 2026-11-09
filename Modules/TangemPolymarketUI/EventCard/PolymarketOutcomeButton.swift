//
//  PolymarketOutcomeButton.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

struct PolymarketOutcomeButton: View {
    let outcome: PolymarketEventCard.Outcome
    let isWide: Bool
    var labelStyle: PolymarketEventCard.OutcomeLabelStyle = .bulletSeparated
    var horizontalPadding: CGFloat = 14

    var body: some View {
        Button(action: outcome.onSelect) {
            label
                .style(DesignSystem.Font.bodyMediumToken, color: outcome.style.foregroundColor)
                .padding(.horizontal, horizontalPadding)
                .frame(minWidth: isWide ? 0 : 56, maxWidth: isWide ? .infinity : nil, minHeight: 36)
                .background(outcome.style.backgroundColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(outcome.priceText.map { "\(outcome.title) \($0)" } ?? outcome.title)
    }

    @ViewBuilder
    private var label: some View {
        switch labelStyle {
        case .bulletSeparated:
            HStack(spacing: Constants.outcomeSpacing) {
                Text(outcome.title)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let priceText = outcome.priceText {
                    Text(Constants.priceSeparator + priceText)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)
                        .contentTransition(.numericText())
                        .animation(Constants.priceChangeAnimation, value: priceText)
                }
            }
        case .compact:
            HStack(spacing: Constants.outcomeSpacing) {
                fadingTitle

                if let priceText = outcome.priceText {
                    Text(priceText)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .contentTransition(.numericText())
                        .animation(Constants.priceChangeAnimation, value: priceText)
                        .clipped()
                        .layoutPriority(1)
                }
            }
            .monospacedDigit()
        }
    }

    private var fadingTitle: some View {
        ViewThatFits(in: .horizontal) {
            Text(outcome.title)

            Text(outcome.title)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .clipped()
                .mask {
                    HStack(spacing: 0) {
                        Color.black

                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: Constants.titleFadeWidth)
                    }
                }
        }
        .lineLimit(1)
    }
}

// MARK: - Constants

private extension PolymarketOutcomeButton {
    enum Constants {
        static let outcomeSpacing: CGFloat = 4
        static let priceSeparator = String.bulletSign + " "
        static let priceChangeAnimation = Animation.curve(.easeInOutRefined, duration: 0.3)
        static let titleFadeWidth: CGFloat = 6
    }
}
