//
//  CommonBuyTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonBuyTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.exchangeService)
    private var exchangeService: ExchangeService
}

// MARK: - TokenAvailabilitySorter

extension CommonBuyTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            if tokenAvailableToBuy(walletModel) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }

    private func tokenAvailableToBuy(_ walletModel: any WalletModel) -> Bool {
        if FeatureProvider.isAvailable(.onramp) {
            expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem)
        } else {
            exchangeService.canBuy(
                walletModel.tokenItem.currencySymbol,
                amountType: walletModel.tokenItem.amountType,
                blockchain: walletModel.tokenItem.blockchain
            )
        }
    }
}
