//
//  MultiDemoWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MultiDemoWalletModelsFactory {
    private let factory: MultiWalletModelsFactory

    init(isHDWalletAllowed: Bool, derivationStyle: DerivationStyle?) {
        factory = MultiWalletModelsFactory(isHDWalletAllowed: isHDWalletAllowed, derivationStyle: derivationStyle)
    }
}

extension MultiDemoWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel] {
        let models = try factory.makeWalletModels(for: token, keys: keys)

        let demoUtil = DemoUtil()

        models.forEach {
            $0.demoBalance = demoUtil.getDemoBalance(for: $0.wallet.blockchain)
        }

        return models
    }
}
