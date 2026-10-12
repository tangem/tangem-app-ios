//
//  FeedAddAccountWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct FeedAddAccountWidgetView: View {
    @ScaledMetric private var accessorySide: CGFloat = Constants.accessorySide
    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide

    var body: some View {
        FeedCompactCardView(title: Localization.accountFormCreateButton) {
            icon
        }
    }
}

// MARK: - Subviews

private extension FeedAddAccountWidgetView {
    var icon: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconSide))
            .foregroundStyle(DesignSystem.Color.iconStaticDark)
            .frame(size: CGSize(bothDimensions: accessorySide))
            .background(DesignSystem.Color.bgAccentBlue, in: Circle())
            .overlay { Circle().strokeBorder(DesignSystem.Color.paletteOpaqueBaseWhite10, lineWidth: 0.5) }
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension FeedAddAccountWidgetView {
    enum Constants {
        static let accessorySide: CGFloat = 24
        static let iconSide: CGFloat = 16
    }
}
