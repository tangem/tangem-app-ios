//
//  PriceAlertsWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PriceAlertsWalletSelectorView: View {
    @ObservedObject var viewModel: PriceAlertsWalletSelectorViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: Localization.commonChooseWallet,
                backAction: nil,
                closeAction: viewModel.closeTapped
            )
        ) {
            content
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var content: some View {
        VStack(spacing: 16) {
            walletList

            MainButton(
                title: Localization.commonSave,
                isDisabled: !viewModel.isAddEnabled,
                action: viewModel.addToPriceAlertTapped
            )
        }
        .padding(.top, 8)
        .padding([.horizontal, .bottom], 16)
    }

    private var walletList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.walletItems) { itemViewModel in
                PriceAlertsWalletRowView(viewModel: itemViewModel)
            }
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - PriceAlertsWalletRowView

struct PriceAlertsWalletRowView: View {
    @ObservedObject var viewModel: WalletSelectorItemViewModel

    var body: some View {
        TangemRow(title: viewModel.name, subtitle: viewModel.cardSetLabel)
            .start { icon }
            .subtitleAccessory { balanceLine }
            .end {
                TangemCheckmarkV2(checked: viewModel.isSelected) {
                    viewModel.onTapAction()
                }
            }
            .contentLead(.equal)
            .showDivider(false)
            .onTap { viewModel.onTapAction() }
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

    private var balanceLine: some View {
        HStack(spacing: 4) {
            Text(AppConstants.dotSign)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            LoadableBalanceView(
                state: viewModel.balanceState,
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: CGSize(width: 40, height: 12))
            )
        }
    }
}

// MARK: - Previews

#Preview {
    let cardSetLabel = UserWalletModelMock().config.cardSetLabel

    VStack(spacing: 0) {
        PriceAlertsWalletRowView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            cardSetLabel: cardSetLabel,
            isUserWalletLocked: false,
            infoProvider: FakeUserWalletModel.wallet3Cards,
            totalBalancePublisher: FakeUserWalletModel.wallet3Cards.totalBalancePublisher,
            isSelected: true,
            didTapWallet: { _ in }
        ))

        PriceAlertsWalletRowView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            cardSetLabel: cardSetLabel,
            isUserWalletLocked: false,
            infoProvider: FakeUserWalletModel.wallet3Cards,
            totalBalancePublisher: FakeUserWalletModel.wallet3Cards.totalBalancePublisher,
            isSelected: false,
            didTapWallet: { _ in }
        ))
    }
    .background(Colors.Background.action)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Colors.Background.tertiary)
}
