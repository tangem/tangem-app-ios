//
//  SwappingConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk

/// Helper for configure `SwappingViewModel`
struct SwappingConfigurator {
    private let factory: DependenciesFactory

    init(factory: DependenciesFactory) {
        self.factory = factory
    }

    func createModule(input: InputModel, coordinator: SwappingRoutable) -> SwappingViewModel {
        let exchangeManager = factory.createExchangeManager(
            walletModel: input.walletModel,
            source: input.source,
            destination: input.destination
        )

        return SwappingViewModel(
            exchangeManager: exchangeManager,
            swappingDestinationService: factory.createSwappingDestinationService(walletModel: input.walletModel),
            userCurrenciesProvider: factory.createUserCurrenciesProvider(walletModel: input.walletModel),
            tokenIconURLBuilder: factory.createTokenIconURLBuilder(),
            transactionSender: factory.createTransactionSender(walletManager: input.walletModel.walletManager, signer: input.signer),
            fiatRatesProvider: factory.createFiatRatesProvider(walletModel: input.walletModel),
            coordinator: coordinator
        )
    }
}

extension SwappingConfigurator {
    struct InputModel {
        let walletModel: WalletModel
        let sender: TransactionSender
        let signer: TransactionSigner
        let source: Currency
        let destination: Currency?

        init(
            walletModel: WalletModel,
            sender: TransactionSender,
            signer: TransactionSigner,
            source: Currency,
            destination: Currency? = nil
        ) {
            self.walletModel = walletModel
            self.sender = sender
            self.signer = signer
            self.source = source
            self.destination = destination
        }
    }
}
