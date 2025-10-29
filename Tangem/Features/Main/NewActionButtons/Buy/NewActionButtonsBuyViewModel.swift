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

    lazy var tokenSelectorViewModel = NewTokenSelectorViewModel(
        walletsProvider: walletsProvider,
        output: self
    )

    // MARK: - Private

    private let walletsProvider = CommonNewTokenSelectorWalletsProvider(
        availabilityProviderFactory: NewTokenSelectorItemBuyAvailabilityProviderFactory()
    )

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(coordinator: some ActionButtonsBuyRoutable) {
        self.coordinator = coordinator
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

        let sendInput = SendInput(userWalletInfo: item.wallet.userWalletInfo, walletModel: item.walletModel)
        coordinator?.openOnramp(input: sendInput)
    }
}
