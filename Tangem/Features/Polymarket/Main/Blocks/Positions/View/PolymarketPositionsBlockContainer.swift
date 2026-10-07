//
//  PolymarketPositionsBlockContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketPositionsBlockContainer<Content: View>: View {
    let hasFinishedPositions: Bool
    let onOpenFinished: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: Constants.spacing) {
            header

            content
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topSpacing)
    }
}

// MARK: - Subviews

private extension PolymarketPositionsBlockContainer {
    var header: some View {
        HStack(spacing: Constants.spacing) {
            Text(Localization.predictionPositionsMainTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            finishedButton
        }
    }

    /// The badge is taller than the title, so it holds its place instead of pushing the list down when it arrives.
    var finishedButton: some View {
        SwiftUI.Button(action: onOpenFinished) {
            Badge(label: Localization.predictionPositionsFinished, accessibilityLabel: nil)
                .size(.x9)
                .slotEnd(DesignSystem.Icons.ChevronRight.regular16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.predictionPositionsFinished)
        .visible(hasFinishedPositions)
        .allowsHitTesting(hasFinishedPositions)
        .accessibilityHidden(!hasFinishedPositions)
    }
}

// MARK: - Constants

private enum Constants {
    static let topSpacing: CGFloat = 52
    static let spacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
}
