//
//  GenericWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GenericWalletFactory: AnyWalletFactory {
    private let dataStorage: BlockchainDataStorage

    init(dataStorage: BlockchainDataStorage) {
        self.dataStorage = dataStorage
    }

    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        switch blockchainNetwork.blockchain {
        case .chia:
            return try SimpleWalletFactory().makeWallet(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case .cardano(extended: true):
            return try CardanoWalletFactory().makeWallet(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case .quai:
            return try QuaiWalletFactory(dataStorage: dataStorage).makeWallet(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case _ where blockchainNetwork.isDynamicAddressesEnabled():
            return try BitcoinXPUBWalletFactory().makeWallet(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        default:
            return try HDWalletFactory().makeWallet(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        }
    }
}
