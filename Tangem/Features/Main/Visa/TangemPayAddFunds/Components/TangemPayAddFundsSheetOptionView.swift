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
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }
}

// MARK: - Redesigned

private extension TangemPayAddFundsSheetOptionView {
    var redesignedBody: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Tokens.Spacing.s150) {
                redesignedIcon

                redesignedTitleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignSystem.Tokens.Spacing.s150)
        }
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    var redesignedIcon: some View {
        option.redesignedIcon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
            .foregroundStyle(DesignSystem.Tokens.Theme.Icon.brand)
            .frame(width: DesignSystem.Tokens.Size.s500, height: DesignSystem.Tokens.Size.s500)
            .background(DesignSystem.Tokens.Theme.Bg.Status.infoSubtle, in: Circle())
    }

    var redesignedTitleView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s025) {
            Text(option.title)
                .font(DesignSystem.Tokens.Font.Subheading.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

            Text(option.subtitle)
                .font(DesignSystem.Tokens.Font.Caption.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Legacy

private extension TangemPayAddFundsSheetOptionView {
    var legacyBody: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon

                titleView
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 14)
        }
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    var icon: some View {
        Colors.Icon.accent.opacity(0.1)
            .frame(width: 36, height: 36)
            .overlay {
                option.icon.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)
            }
            .clipShape(Circle())
    }

    var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(option.subtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .multilineTextAlignment(.leading)
    }
}

extension TangemPayAddFundsSheetOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case receive
        case swap

        var title: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveTitle
            case .swap: Localization.tangempayTopupSwapTitle
            }
        }

        var subtitle: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveBody
            case .swap: Localization.tangempayTopupSwapBody
            }
        }

        var icon: ImageType {
            switch self {
            case .receive: Assets.arrowDownMini
            case .swap: Assets.exchangeMini
            }
        }

        var redesignedIcon: ImageType {
            switch self {
            case .receive: Assets.Visa.grid
            case .swap: DesignSystem.Icons.LogoTangem.regular20
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .receive: TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
            case .swap: TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
            }
        }
    }
}
