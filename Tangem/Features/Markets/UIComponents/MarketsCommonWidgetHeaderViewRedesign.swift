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

struct MarketsCommonWidgetHeaderViewRedesign: View {
    let headerTitle: String
    let headerImage: Image?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoadingState: MarketsCommonWidgetHeaderView.LoadingState

    @ScaledSize private var chevronSize = CGSize(width: 24, height: 24)
    @ScaledSize private var headerSkeletonSize = CGSize(width: 120, height: 24)

    private var isDisplayButton: Bool {
        return buttonTitle != nil && isLoadingState.isButtonVisibility
    }

    var body: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(headerTitle)
                .lineLimit(1)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .skeletonable(
                    isShown: isLoadingState.isHeaderSkeletonable,
                    size: headerSkeletonSize,
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
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
                    .frame(size: chevronSize)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSeeAllButton)
    }
}
