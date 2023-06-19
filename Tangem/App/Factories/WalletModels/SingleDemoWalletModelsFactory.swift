//
//  SingleDemoWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SingleDemoWalletModelsFactory {
    private let factory: SingleWalletModelsFactory = .init()
}

extension SingleDemoWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel] {
        let models = try factory.makeWalletModels(for: token, keys: keys)

        let demoUtil = DemoUtil()

        models.forEach {
            $0.demoBalance = demoUtil.getDemoBalance(for: $0.wallet.blockchain)
        }

        return models
    }
}
