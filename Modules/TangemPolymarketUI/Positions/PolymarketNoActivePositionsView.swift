//
//  PolymarketNoActivePositionsView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketNoActivePositionsView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Constants.spacing) {
            icon

            VStack(spacing: 0) {
                Text(Constants.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                Text(Constants.subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, Constants.verticalPadding)
        .frame(maxWidth: .infinity)
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
        )
    }

    private var icon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.iconSide, height: Constants.iconSide)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: Constants.iconContainerSide, height: Constants.iconContainerSide)
            .background(DesignSystem.Color.bgTransparentSecondary, in: Circle())
            .opacity(Constants.iconContainerOpacity)
    }
}

// MARK: - Constants

private extension PolymarketNoActivePositionsView {
    enum Constants {
        static let title = Localization.predictionMainEmptyPositionsTitle
        static let subtitle = Localization.predictionMainEmptyPositionsSubtitle
        static let spacing: CGFloat = 16
        static let verticalPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 24
        static let iconSide: CGFloat = 20
        static let iconContainerSide: CGFloat = 40
        static let iconContainerOpacity: Double = 0.9
    }
}

// MARK: - Previews

#Preview {
    PolymarketNoActivePositionsView()
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
