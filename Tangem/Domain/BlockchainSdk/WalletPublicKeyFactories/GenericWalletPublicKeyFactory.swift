//
//  GenericWalletPublicKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GenericWalletPublicKeyFactory: AnyWalletPublicKeyFactory {
    private let dataStorage: BlockchainDataStorage?

    init(dataStorage: BlockchainDataStorage? = nil) {
        self.dataStorage = dataStorage
    }

    func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey {
        switch blockchainNetwork.blockchain {
        case .chia:
            return try SimpleWalletPublicKeyFactory().makePublicKey(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case .cardano(extended: true):
            return try CardanoWalletPublicKeyFactory().makePublicKey(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case .quai:
            return try QuaiWalletPublicKeyFactory(dataStorage: dataStorage).makePublicKey(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        case _ where blockchainNetwork.isDynamicAddressesEnabled():
            return try BitcoinXPUBPublicKeyFactory().makePublicKey(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        default:
            return try HDWalletPublicKeyFactory().makePublicKey(
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        }
    }
}
