//
//  GenericWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GenericWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> WalletManager {
        switch token.blockchainNetwork.blockchain {
        case .chia:
            return try SimpleWalletManagerFactory().makeWalletManager(for: token, keys: keys)
        case .cardano(let extended):
            if extended {
                return try CardanoWalletManagerFactory().makeWalletManager(for: token, keys: keys)
            } else {
                fallthrough
            }
        default:
            return try HDWalletManagerFactory().makeWalletManager(for: token, keys: keys)
        }
    }
}
