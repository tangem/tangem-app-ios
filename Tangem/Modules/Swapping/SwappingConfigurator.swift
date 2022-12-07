//
//  SwappingConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

import protocol BlockchainSdk.TransactionSigner

/// Helper for configure `SwappingViewModel`
struct SwappingConfigurator {
    private let factory = DependenciesFactory()

    func createModule(input: InputModel, coordinator: SwappingRoutable) -> SwappingViewModel {
        let exchangeManager = factory.createExchangeManager(
            walletModel: input.walletModel,
            signer: input.signer,
            source: input.source,
            destination: input.destination
        )

        return SwappingViewModel(
            exchangeManager: exchangeManager,
            tokenIconURLBuilding: factory.createTokenIconURLBuilder(),
            coordinator: coordinator
        )
    }
}

extension SwappingConfigurator {
    struct InputModel {
        let walletModel: WalletModel
        let signer: TransactionSigner
        let source: Currency
        let destination: Currency
    }
}
