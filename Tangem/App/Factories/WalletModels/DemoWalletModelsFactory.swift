//
//  DemoWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct DemoWalletModelsFactory {
    private let factory: CommonWalletModelsFactory

    init(derivationStyle: DerivationStyle?) {
        factory = CommonWalletModelsFactory(derivationStyle: derivationStyle)
    }
}

extension DemoWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        let models = factory.makeWalletModels(from: walletManager)

        let demoUtil = DemoUtil()

        models.forEach {
            $0.demoBalance = demoUtil.getDemoBalance(for: $0.wallet.blockchain)
        }

        return models
    }
}
