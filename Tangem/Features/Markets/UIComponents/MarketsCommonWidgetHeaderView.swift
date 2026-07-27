//
//  MarketsCommonWidgetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsCommonWidgetHeaderView: View {
    let headerTitle: String
    let headerImage: Image?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoadingState: MarketsCommonWidgetHeaderLoadingState

    @ScaledMetric private var chevronSide: CGFloat = 24
    @ScaledMetric private var scaleFactor: CGFloat = 1

    private var isDisplayButton: Bool {
        return buttonTitle != nil && isLoadingState.isButtonVisibility
    }

    var body: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(headerTitle)
                .lineLimit(1)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .skeletonable(
                    isShown: isLoadingState.isHeaderSkeletonable,
                    size: CGSize(width: 120, height: 24) * scaleFactor,
                    cornerStyle: .capsule
                )

            if let headerImage = headerImage {
                FixedSpacer(width: 8)

                headerImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .hidden(isLoadingState.isHeaderSkeletonable)
            }

            Spacer(minLength: 8)

            if isDisplayButton {
                buttonView
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private var buttonView: some View {
        SwiftUI.Button {
            buttonAction?()
        } label: {
            HStack(spacing: 0) {
                Text(buttonTitle ?? "")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: chevronSide, height: chevronSide)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSeeAllButton)
    }
}
