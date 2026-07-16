//
//  TangemPayAddFundsSheetOptionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemMacro

struct TangemPayAddFundsSheetOptionView: View {
    let option: Option
    let action: () -> Void

    var body: some View {
        redesignedBody
    }
}

// MARK: - Redesigned

private extension TangemPayAddFundsSheetOptionView {
    var redesignedBody: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                redesignedIcon

                redesignedTitleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    var redesignedIcon: some View {
        option.redesignedIcon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
    }

    var redesignedTitleView: some View {
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

extension TangemPayAddFundsSheetOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case receive
        case swap
        case bankTransfer

        var title: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveTitle
            case .swap: Localization.tangempayTopupSwapTitle
            case .bankTransfer: Localization.tangempayTopupBankTransferTitle
            }
        }

        var subtitle: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveBody
            case .swap: Localization.tangempayTopupSwapBody
            case .bankTransfer: Localization.tangempayTopupBankTransferBody
            }
        }

        var redesignedIcon: ImageType {
            switch self {
            case .receive: Assets.Visa.grid
            case .swap: DesignSystem.Icons.LogoTangem.regular20
            case .bankTransfer: Assets.dollarMini
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .receive: TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
            case .swap: TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
            case .bankTransfer: TangemPayAccessibilityIdentifiers.addFundsSheetBankTransferOption
            }
        }
    }
}
