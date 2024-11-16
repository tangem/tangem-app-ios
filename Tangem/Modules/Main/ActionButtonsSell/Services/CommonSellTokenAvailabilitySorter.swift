//
//  CommonSellTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonSellTokenAvailabilitySorter: TokenAvailabilitySorter {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in
            if exchangeService.canSell(
                walletModel.tokenItem.currencySymbol,
                amountType: walletModel.amountType,
                blockchain: walletModel.blockchainNetwork.blockchain
            ) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
