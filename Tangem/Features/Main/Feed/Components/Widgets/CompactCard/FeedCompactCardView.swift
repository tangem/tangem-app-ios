//
//  FeedCompactCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct FeedCompactCardView<Icon: View>: View {
    let title: String
    @ViewBuilder let icon: () -> Icon

    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            icon()
                .frame(size: CGSize(bothDimensions: iconSide))

            Spacer(minLength: 0)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Constants.padding)
        .padding(.top, Constants.padding)
        .padding(.bottom, Constants.bottomPadding)
        .infinityFrame(alignment: .leading)
        .background {
            FeedWidgetBackground(defaultColor: DesignSystem.Color.bgOpaquePrimary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let padding: CGFloat = 16
    static let bottomPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 24
    static let iconSide: CGFloat = 24
}
