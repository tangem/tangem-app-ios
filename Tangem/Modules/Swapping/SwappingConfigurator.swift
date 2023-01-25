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
    private let factory: SwappingDependenciesFactoring

    init(factory: SwappingDependenciesFactoring) {
        self.factory = factory
    }

    func createModule(input: InputModel, coordinator: SwappingRoutable) -> SwappingViewModel {
        SwappingViewModel(
            exchangeManager: factory.exchangeManager(source: input.source, destination: input.destination),
            swappingDestinationService: factory.swappingDestinationService(),
            userCurrenciesProvider: factory.userCurrenciesProvider(),
            tokenIconURLBuilder: factory.tokenIconURLBuilder(),
            transactionSender: factory.transactionSender(),
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
