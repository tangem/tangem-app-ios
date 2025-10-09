//
//  GenericWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct GenericWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        switch token.blockchainNetwork.blockchain {
        case .chia:
            return try SimpleWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
        case .cardano(let extended):
            if extended {
                return try CardanoWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
            } else {
                return try HDWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
            }
        case .quai:
            let dataStorage = UserDefaultsBlockchainDataStorage(
                suiteName: AppEnvironment.current.blockchainDataStorageSuiteName
            )

            return try QuaiWalletManagerFactory(dataStorage: dataStorage)
                .makeWalletManager(for: token, keys: keys, apiList: apiList)
        default:
            return try HDWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
        }
    }
}
