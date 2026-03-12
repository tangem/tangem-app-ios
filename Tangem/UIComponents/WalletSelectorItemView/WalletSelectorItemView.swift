//
//  WalletSelectorItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WalletSelectorItemView: View {
    @ObservedObject var viewModel: WalletSelectorItemViewModel

    var body: some View {
        Button {
            viewModel.onTapAction()
        } label: {
            contentButton
        }
        .accessibilityIdentifier(viewModel.name)
    }

    // MARK: - Private Implementation

    private var contentButton: some View {
        VStack(spacing: .zero) {
            HStack(spacing: 12) {
                icon

                textViews

                Spacer(minLength: 0)

                selectedCheckmark
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Text(viewModel.cardSetLabel)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                LoadableBalanceView(
                    state: viewModel.balanceState,
                    style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
            .lineLimit(1)
        }
    }

    private var selectedCheckmark: some View {
        VStack {
            if viewModel.isSelected {
                Assets.check.image
                    .frame(width: 24, height: 24)
                    .foregroundColor(Colors.Icon.accent)
            }
        }
    }

    private var icon: some View {
        image
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.icon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            )
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.icon {
        case .loading:
            Color.clear

        case .success(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failure:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

extension WalletSelectorItemView {
    enum Constants {
        static let checkedSelectedIconSize = CGSize(bothDimensions: 24)
        static let balanceSkeletonLoaderText = "--------"
    }
}

#Preview {
    let cardSetLabel = UserWalletModelMock().config.cardSetLabel

    VStack {
        WalletSelectorItemView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            cardSetLabel: cardSetLabel,
            isUserWalletLocked: false,
            infoProvider: FakeUserWalletModel.wallet3Cards,
            totalBalancePublisher: FakeUserWalletModel.wallet3Cards.totalBalancePublisher,
            isSelected: true,
            didTapWallet: { _ in }
        )
        )

        WalletSelectorItemView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            cardSetLabel: cardSetLabel,
            isUserWalletLocked: false,
            infoProvider: FakeUserWalletModel.wallet3Cards,
            totalBalancePublisher: FakeUserWalletModel.wallet3Cards.totalBalancePublisher,
            isSelected: false,
            didTapWallet: { _ in }
        )
        )
    }
}
