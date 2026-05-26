//
//  AddFundsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI

@MainActor
final class AddFundsViewModel: ObservableObject {
    let tokenIconInfo: TokenIconInfo
    let fiatBalanceText: String
    let cryptoBalanceText: String

    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: AddFundsCoordinator?

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        coordinator: AddFundsCoordinator
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator

        let iconBuilder = TokenIconInfoBuilder()
        tokenIconInfo = iconBuilder.build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)

        let formatter = BalanceFormatter()
        fiatBalanceText = formatter.formatFiatBalance(walletModel.fiatAvailableBalanceProvider.balanceType.value)
        cryptoBalanceText = formatter.formatCryptoBalance(
            walletModel.availableBalanceProvider.balanceType.value,
            currencyCode: walletModel.tokenItem.currencySymbol
        )
    }

    func onBuy() {
        coordinator?.openBuy(userWalletInfo: userWalletInfo, walletModel: walletModel)
    }

    func onSwap() {
        coordinator?.openSwap(userWalletInfo: userWalletInfo, walletModel: walletModel)
    }

    func onReceive() {
        coordinator?.openReceive(walletModel: walletModel)
    }

    func onGoToToken() {
        coordinator?.openTokenDetails(userWalletInfo: userWalletInfo, walletModel: walletModel)
    }

    func onClose() {
        coordinator?.closeAddFunds()
    }
}
