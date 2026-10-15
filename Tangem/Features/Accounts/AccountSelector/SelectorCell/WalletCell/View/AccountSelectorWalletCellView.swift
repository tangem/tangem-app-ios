//
//  AccountSelectorWalletCellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct AccountSelectorWalletCellButtonView: View {
    @StateObject var viewModel: AccountSelectorWalletCellViewModel

    private let onTap: () -> Void
    private var style: Style = .legacy
    private var isSelected: Bool?

    init(walletModel: AccountSelectorWalletItem, onTap: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: .init(walletModel: walletModel))
        self.onTap = onTap
    }

    var body: some View {
        SwiftUI.Button(action: onTap) {
            content
                .task { [weak viewModel] in
                    await viewModel?.loadWalletImage()
                }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isDisabled)
        .accessibilityAddTraits(isSelected == true ? .isSelected : [])
        .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.accountSelectorCell(name: viewModel.walletModel.name))
    }

    private var content: some View {
        HStack(spacing: 12) {
            walletImage
                .frame(size: .init(bothDimensions: style.iconSide))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.walletModel.name)
                    .style(
                        style.titleFont,
                        color: viewModel.isDisabled ? Colors.Text.disabled : style.titleColor
                    )

                walletDescription
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let isSelected {
                TangemUI.Checkmark(checked: isSelected, action: {})
                    .expandsHitArea(false)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .lineLimit(1)
        .padding(style.padding)
        .contentShape(.rect)
        .saturation(viewModel.isDisabled ? 0 : 1)
    }

    private var walletImage: some View {
        unwrappedWalletIcon
            .shimmerPlaceholder(
                viewModel.walletIcon.isLoading,
                variant: .custom(width: style.iconSide, height: style.iconSkeletonHeight, cornerRadius: 3)
            )
            .opacity(viewModel.isDisabled ? 0.5 : 1)
    }

    @ViewBuilder
    private var unwrappedWalletIcon: some View {
        switch viewModel.walletIcon {
        case .loading:
            Color.clear

        case .success(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    @ViewBuilder
    private var walletDescription: some View {
        switch viewModel.walletModel.wallet {
        case .active(let activeWallet):
            makeActiveWalletDescription(
                for: activeWallet,
                with: viewModel.walletModel.accountAvailability
            )

        case .locked(let lockedWallet):
            lockedWalletDescription(lockedWallet.cardsLabel)
        }
    }

    @ViewBuilder
    private func makeActiveWalletDescription(
        for activeWallet: AccountSelectorWalletItem.UserWallet.ActiveWallet,
        with availability: AccountAvailability
    ) -> some View {
        switch availability {
        case .unavailable(let reason):
            makeUnavailableDescription(for: activeWallet, reason: reason)
                .opacity(viewModel.isDisabled ? 0.5 : 1)
        case .available:
            activeWalletDescription(activeWallet.tokensCount)
        }
    }

    @ViewBuilder
    private func makeUnavailableDescription(
        for activeWallet: AccountSelectorWalletItem.UserWallet.ActiveWallet,
        reason: String?
    ) -> some View {
        if let reason {
            Text(reason)
                .style(style.subtitleFont, color: style.subtitleColor)
        } else {
            activeWalletDescription(activeWallet.tokensCount)
        }
    }

    private func activeWalletDescription(_ tokensCount: String) -> some View {
        HStack(spacing: 4) {
            Text(tokensCount)
                .style(style.subtitleFont, color: style.subtitleColor)

            if viewModel.fiatBalanceState != .empty {
                Text(AppConstants.dotSign)
                    .style(style.subtitleFont, color: style.subtitleColor)

                LoadableBalanceView(
                    state: viewModel.fiatBalanceState,
                    style: .init(font: style.subtitleFont, textColor: style.subtitleColor),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
        }
    }

    private func lockedWalletDescription(_ cardSetLabel: String) -> some View {
        HStack(spacing: 4) {
            Text(cardSetLabel)
                .style(style.subtitleFont, color: Colors.Text.disabled)

            Assets.Glyphs.lockNew.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.inactive)
        }
    }
}

// MARK: - Setupable

extension AccountSelectorWalletCellButtonView: Setupable {
    func style(_ style: Style) -> Self {
        map { $0.style = style }
    }

    func selection(_ isSelected: Bool?) -> Self {
        map { $0.isSelected = isSelected }
    }
}

// MARK: - Style

extension AccountSelectorWalletCellButtonView {
    struct Style {
        let padding: CGFloat
        let iconSide: CGFloat
        let iconSkeletonHeight: CGFloat
        let titleFont: TangemFontStyle
        let titleColor: Color
        let subtitleFont: TangemFontStyle
        let subtitleColor: Color

        static let legacy = Style(
            padding: 14,
            iconSide: 36,
            iconSkeletonHeight: 22,
            titleFont: TangemFontStyle(font: Fonts.Bold.subheadline),
            titleColor: Colors.Text.primary1,
            subtitleFont: TangemFontStyle(font: Fonts.Regular.caption1),
            subtitleColor: Colors.Text.tertiary
        )

        static let modal = Style(
            padding: 16,
            iconSide: 40,
            iconSkeletonHeight: 24,
            titleFont: TangemFontStyle(DesignSystem.Font.bodyMediumToken),
            titleColor: DesignSystem.Color.textPrimary,
            subtitleFont: TangemFontStyle(DesignSystem.Font.captionMediumToken),
            subtitleColor: DesignSystem.Color.textSecondary
        )
    }
}
