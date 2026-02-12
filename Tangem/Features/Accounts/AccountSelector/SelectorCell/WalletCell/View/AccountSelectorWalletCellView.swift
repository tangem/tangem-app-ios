//
//  AccountSelectorWalletCellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AccountSelectorWalletCellButtonView: View {
    @StateObject var viewModel: AccountSelectorWalletCellViewModel

    private let onTap: () -> Void

    init(walletModel: AccountSelectorWalletItem, onTap: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: .init(walletModel: walletModel))
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            content
                .task { [weak viewModel] in
                    await viewModel?.loadWalletImage()
                }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isDisabled)
    }

    private var content: some View {
        HStack(spacing: 12) {
            walletImage
                .frame(width: 36, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.walletModel.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: viewModel.isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                    )

                walletDescription
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .padding(14)
        .contentShape(.rect)
        .saturation(viewModel.isDisabled ? 0 : 1)
    }

    private var walletImage: some View {
        unwrappedWalletIcon
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.walletIcon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
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
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        } else {
            activeWalletDescription(activeWallet.tokensCount)
        }
    }

    private func activeWalletDescription(_ tokensCount: String) -> some View {
        HStack(spacing: 4) {
            Text(tokensCount)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            if viewModel.fiatBalanceState != .empty {
                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                LoadableBalanceView(
                    state: viewModel.fiatBalanceState,
                    style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
        }
    }

    private func lockedWalletDescription(_ cardSetLabel: String) -> some View {
        HStack(spacing: 4) {
            Text(cardSetLabel)
                .style(Fonts.Regular.caption1, color: Colors.Text.disabled)

            Assets.Glyphs.lockNew.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.inactive)
        }
    }
}
