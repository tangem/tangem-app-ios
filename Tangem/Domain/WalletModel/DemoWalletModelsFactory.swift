//
//  DemoWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct DemoWalletModelsFactory {
    private let factory: CommonWalletModelsFactory

    init(config: UserWalletConfig, userWalletId: UserWalletId) {
        factory = CommonWalletModelsFactory(config: config, userWalletId: userWalletId)
    }
}

extension DemoWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: any WalletManager, cryptoAccountModel: (any CryptoAccountModel)?) -> [any WalletModel] {
        return factory.makeWalletModels(from: walletManager, cryptoAccountModel: cryptoAccountModel)
    }

    func makeWalletModels(
        for types: [Amount.AmountType],
        walletManager: WalletManager,
        blockchainNetwork: BlockchainNetwork,
        cryptoAccountModel: (any CryptoAccountModel)?
    ) -> [any WalletModel] {
        let blockchain = walletManager.wallet.blockchain
        let derivationPath = walletManager.wallet.publicKey.derivationPath
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)

        let models = factory.makeWalletModels(
            for: types,
            walletManager: walletManager,
            blockchainNetwork: blockchainNetwork,
            cryptoAccountModel: cryptoAccountModel,
        )

        let demoUtil = DemoUtil()

        models.forEach {
            $0.demoBalance = demoUtil.getDemoBalance(for: $0.tokenItem.blockchain)
        }

        return models
    }
}
