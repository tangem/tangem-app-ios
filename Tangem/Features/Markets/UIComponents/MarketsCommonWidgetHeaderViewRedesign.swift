//
//  MarketsCommonWidgetHeaderViewRedesign.swift
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

struct MarketsCommonWidgetHeaderViewRedesign: View {
    let headerTitle: String
    let headerImage: Image?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoadingState: MarketsCommonWidgetHeaderView.LoadingState

    @ScaledMetric private var chevronSide: CGFloat = 24
    @ScaledMetric private var scaleFactor: CGFloat = 1

    private var isDisplayButton: Bool {
        return buttonTitle != nil && isLoadingState.isButtonVisibility
    }

    var body: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(headerTitle)
                .lineLimit(1)
                .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .skeletonable(
                    isShown: isLoadingState.isHeaderSkeletonable,
                    size: CGSize(width: 120, height: 24) * scaleFactor,
                    cornerStyle: .capsule
                )

            if let headerImage = headerImage {
                FixedSpacer(width: SizeUnit.x2.value)

                headerImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: SizeUnit.x5.value)
                    .hidden(isLoadingState.isHeaderSkeletonable)
            }

            Spacer(minLength: SizeUnit.x2.value)

            if isDisplayButton {
                buttonView
            }
        }
        .padding(.vertical, SizeUnit.x2.value)
        .padding(.horizontal, SizeUnit.x2.value)
    }

    private var buttonView: some View {
        Button {
            buttonAction?()
        } label: {
            HStack(spacing: 0) {
                Text(buttonTitle ?? "")
                    .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
                    .frame(width: chevronSide, height: chevronSide)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSeeAllButton)
    }
}
