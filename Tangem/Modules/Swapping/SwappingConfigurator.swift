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
            signer: input.signer,
            source: input.source,
            destination: input.destination
        )

        return SwappingViewModel(
            exchangeManager: exchangeManager,
            userWalletsListProvider: factory.createUserWalletsListProvider(walletModel: input.walletModel),
            tokenIconURLBuilder: factory.createTokenIconURLBuilder(),
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
