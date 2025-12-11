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

struct AccountSelectorWalletCellView: View {
    @StateObject var viewModel: AccountSelectorWalletCellViewModel

    init(walletModel: AccountSelectorWalletItem) {
        _viewModel = StateObject(wrappedValue: .init(walletModel: walletModel))
    }

    var body: some View {
        content
            .task { [weak viewModel] in
                await viewModel?.loadWalletImage()
            }
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
                        color: viewModel.isLocked ? Colors.Text.disabled : Colors.Text.primary1
                    )

                walletDescription
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .padding(14)
        .contentShape(.rect)
        .saturation(viewModel.isLocked ? 0 : 1)
    }

    private var walletImage: some View {
        unwrappedWalletIcon
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.walletIcon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            )
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
    var walletDescription: some View {
        switch viewModel.walletModel.wallet {
        case .active(let activeWallet):
            activeWalletDescription(activeWallet.tokensCount)
        case .locked(let lockedWallet):
            lockedWalletDescription(lockedWallet.cardsLabel)
        }
    }

    func activeWalletDescription(_ tokensCount: String) -> some View {
        HStack(spacing: 4) {
            Text(tokensCount)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            if viewModel.fiatBalanceState != .empty {
                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                LoadableTokenBalanceView(
                    state: viewModel.fiatBalanceState,
                    style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
        }
    }

    func lockedWalletDescription(_ cardSetLabel: String) -> some View {
        HStack(spacing: 4) {
            Text(cardSetLabel)
                .style(Fonts.Regular.caption1, color: Colors.Text.disabled)

            Assets.Glyphs.lockNew.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.inactive)
        }
    }
}
