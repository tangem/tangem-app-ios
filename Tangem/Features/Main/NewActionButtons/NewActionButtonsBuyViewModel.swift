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

    // MARK: - Published properties

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    // MARK: - Child viewModel

    let walletsProvider = CommonNewTokenSelectorWalletsProvider()
    let availabilityProvider = OnrampNewTokenSelectorItemAvailabilityProvider()
    lazy var tokenSelectorViewModel = NewTokenSelectorViewModel(
        walletsProvider: walletsProvider,
        availabilityProvider: availabilityProvider,
        output: self
    )

    // MARK: - Private property

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

        coordinator?.openOnramp(
            input: .init(
                userWalletInfo: item.wallet.userWalletInfo,
                walletModel: item.walletModel,
                expressInput: .init(
                    userWalletInfo: item.wallet.userWalletInfo,
                    refcode: item.wallet.userWalletInfo.refcode,
                    walletModelsManager: item.account.walletModelsManager
                )
            )
        )
    }
}
