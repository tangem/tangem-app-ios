//
//  AccountsAwareActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class AccountsAwareActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    // MARK: - Private

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        coordinator: some ActionButtonsBuyRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.buy)
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
        coordinator?.dismiss()
    }

    func userDidTapHotCryptoToken(_ token: HotCryptoToken) {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
    }

    func userDidRequestAddHotCryptoToken(_ token: HotCryptoToken) {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension AccountsAwareActionButtonsBuyViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: item.walletModel.tokenItem.currencySymbol)

        let sendInput = SendInput(userWalletInfo: item.userWalletInfo, walletModel: item.walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
        coordinator?.openOnramp(input: sendInput, parameters: parameters)
    }
}
