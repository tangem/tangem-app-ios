//
//  PersistentStorageAppScanTaskHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import enum TangemSdk.EllipticCurve
import struct TangemSdk.DerivationPath

/// Provides additional info and features for `AppScanTask` related to persistent storage.
struct PersistentStorageAppScanTaskHelper {
    private let userWalletId: UserWalletId

    private var storageIdentifier: String {
        userWalletId.stringValue
    }

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }

    func isPersistentStorageInitialized() -> Bool {
        if FeatureProvider.isAvailable(.accounts) {
            let storage = CommonCryptoAccountsPersistentStorage(storageIdentifier: storageIdentifier)

            return !storage.isMigrationNeeded()
        } else {
            let tokenItemsRepository = CommonTokenItemsRepository(key: storageIdentifier)

            return tokenItemsRepository.containsFile
        }
    }

    func extractDerivations(forWalletsOnCard card: CardDTO, config: UserWalletConfig) -> [EllipticCurve: [DerivationPath]] {
        var derivations: [EllipticCurve: [DerivationPath]] = [:]
        let persistentBlockchains = config.persistentBlockchains
        let allBlockchainNetworks: Set<BlockchainNetwork>

        if FeatureProvider.isAvailable(.accounts) {
            let storage = CommonCryptoAccountsPersistentStorage(storageIdentifier: storageIdentifier)

            let storedBlockchainNetworks = storage
                .getList()
                .flatMap(\.tokens)
                .compactMap(\.blockchainNetwork.knownValue)

            let persistentBlockchainNetworks = persistentBlockchains
                .compactMap(\.blockchainNetwork)

            allBlockchainNetworks = Set(storedBlockchainNetworks + persistentBlockchainNetworks)
        } else {
            let tokenItemsRepository = CommonTokenItemsRepository(key: storageIdentifier)

            // Force add blockchains for demo cards
            if config.persistentBlockchains.isNotEmpty {
                let converter = StorageEntryConverter()
                tokenItemsRepository.append(converter.convertToStoredUserTokens(tokenItems: persistentBlockchains))
            }

            allBlockchainNetworks = tokenItemsRepository
                .getList()
                .entries
                .map(\.blockchainNetwork)
                .toSet()
        }

        for blockchainNetwork in allBlockchainNetworks {
            if let wallet = card.wallets.first(where: { $0.curve == blockchainNetwork.blockchain.curve }) {
                derivations[wallet.curve, default: []].append(contentsOf: blockchainNetwork.derivationPaths())
            }
        }

        return derivations
    }
}
