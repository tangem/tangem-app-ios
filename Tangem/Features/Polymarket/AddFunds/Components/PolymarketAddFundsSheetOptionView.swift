//
//  PolymarketAddFundsSheetOptionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemMacro
import TangemUIUtils

struct PolymarketAddFundsSheetOptionView: View {
    let option: Option
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon

                titleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }
}

// MARK: - Subviews

private extension PolymarketAddFundsSheetOptionView {
    var icon: some View {
        option.icon.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: 20))
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(size: .init(bothDimensions: 40))
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
    }

    var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.title)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Text(option.subtitle)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Option

extension PolymarketAddFundsSheetOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case swap
        case receive

        var title: String {
            switch self {
            case .swap: Localization.tangempayTopupSwapTitle
            case .receive: Localization.tangempayTopupReceiveTitle
            }
        }

        var subtitle: String {
            switch self {
            case .swap: Localization.predictionAddFundsSwapSubtitle
            case .receive: Localization.predictionAddFundsReceiveSubtitle
            }
        }

        var icon: ImageType {
            switch self {
            case .swap: DesignSystem.Icons.LogoTangem.regular20
            case .receive: Assets.Visa.grid
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .swap: PolymarketAccessibilityIdentifiers.addFundsSheetSwapOption
            case .receive: PolymarketAccessibilityIdentifiers.addFundsSheetReceiveOption
            }
        }
    }
}
