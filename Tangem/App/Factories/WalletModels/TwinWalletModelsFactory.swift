//
//  TwinWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TwinsWalletModelFactory: WalletModelsFactory {
    private let pairPublicKey: Data

    init(pairPublicKey: Data) {
        self.pairPublicKey = pairPublicKey
    }

    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel] {
        guard let walletPublicKey = keys.first?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let twinManager = try factory.makeTwinWalletManager(
            walletPublicKey: walletPublicKey,
            pairKey: pairPublicKey,
            isTestnet: AppEnvironment.current.isTestnet
        )

        let model = WalletModel(walletManager: twinManager, amountType: .coin, isCustom: false)
        return [model]
    }
}
