//
//  NewNewActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class NewActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    let tokenSelectorViewModel: NewTokenSelectorViewModel

    // MARK: - Private

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(coordinator: some ActionButtonsBuyRoutable) {
        self.coordinator = coordinator

        tokenSelectorViewModel = NewTokenSelectorViewModel(
            walletsProvider: CommonNewTokenSelectorWalletsProvider(
                availabilityProviderFactory: NewTokenSelectorItemBuyAvailabilityProviderFactory()
            )
        )
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

// MARK: - NewTokenSelectorViewModelOutput

extension NewActionButtonsBuyViewModel: NewTokenSelectorViewModelOutput {
    func usedDidSelect(item: NewTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: item.walletModel.tokenItem.currencySymbol)

        let sendInput = SendInput(userWalletInfo: item.userWalletInfo, walletModel: item.walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
        coordinator?.openOnramp(input: sendInput, parameters: parameters)
    }
}
