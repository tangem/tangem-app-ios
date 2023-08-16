//
//  _CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class _CommonTokenItemsRepository {
    @Injected(\.persistentStorage) private var persistanceStorage: PersistentStorageProtocol

    @AppStorageCompat(StorageKeys.currentStorageVersion)
    private var currentStorageVersion: StorageEntry.Version = .v3

    private var actualStorageVersion: StorageEntry.Version { .v3 }

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonTokenItemsRepository.lockQueue")
    private let key: String
    private var cache: [StorageEntry.V3.Entry]?

    init(key: String) {
        self.key = key

        lockQueue.sync {
            migrateStorageIfNeeded()
            updateCurrentStorageVersion()
        }
    }

    deinit {
        AppLog.shared.debug("\(#function) \(objectDescription(self))")
    }

    private func migrateStorageIfNeeded() {
        let migrator = StorageEntriesMigrator(
            persistanceStorage: persistanceStorage,
            storageWriter: save(_:forCardID:),
            cardID: key
        )
        migrator.migrate(from: currentStorageVersion, to: actualStorageVersion)
    }

    /// - Warning: MUST BE called only AFTER the storage migration has been performed,
    /// otherwise user data may be lost.
    private func updateCurrentStorageVersion() {
        currentStorageVersion = actualStorageVersion
    }
}

// MARK: - Constants

private extension _CommonTokenItemsRepository {
    enum StorageKeys: String {
        case currentStorageVersion = "com.tangem.CommonTokenItemsRepository.currentStorageVersion"
    }
}

// MARK: - TokenItemsRepository protocol conformance

extension _CommonTokenItemsRepository: _TokenItemsRepository {
    var isInitialized: Bool {
        lockQueue.sync {
            // Here it's necessary to distinguish between empty (`[]` value) and non-initialized
            // (`nil` value) storage, therefore direct access to the underlying storage is used here
            let entries: [StorageEntry.V3.Entry]? = try? persistanceStorage.value(for: .wallets(cid: key))
            return entries != nil
        }
    }

    func update(_ tokens: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            save(tokens, forCardID: key)
        }
    }

    func append(_ tokens: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            var existingTokens = fetch(forCardID: key)
            var hasChanges = false
            var existingBlockchainNetworksToUpdate: [StorageEntry.V3.BlockchainNetwork] = []

            let existingTokensGroupedByBlockchainNetworks = Dictionary(
                grouping: existingTokens.enumerated(),
                by: \.element.blockchainNetwork
            )

            let newTokensGroupedByBlockchainNetworks = Dictionary(grouping: tokens, by: \.blockchainNetwork)
            let newBlockchainNetworks = tokens.unique(by: \.blockchainNetwork).map(\.blockchainNetwork)

            for newBlockchainNetwork in newBlockchainNetworks {
                if existingTokensGroupedByBlockchainNetworks[newBlockchainNetwork] != nil {
                    // This blockchain network already exists, and it probably needs to be updated with new tokens
                    existingBlockchainNetworksToUpdate.append(newBlockchainNetwork)
                } else if let newTokens = newTokensGroupedByBlockchainNetworks[newBlockchainNetwork] {
                    // New network, just appending all tokens from it to the end of the existing list
                    existingTokens.append(contentsOf: newTokens)
                    hasChanges = true
                }
            }

            // [REDACTED_TODO_COMMENT]
            for blockchainNetworkToUpdate in existingBlockchainNetworksToUpdate {
                guard
                    let existingTokensForBlockchainNetwork = existingTokensGroupedByBlockchainNetworks[blockchainNetworkToUpdate]?
                    .keyedFirst(by: \.element.contractAddress), // may contain `nil` key
                    let newTokensForBlockchainNetwork = newTokensGroupedByBlockchainNetworks[blockchainNetworkToUpdate]
                else {
                    continue
                }

                for newToken in newTokensForBlockchainNetwork {
                    if let (existingIndex, existingToken) = existingTokensForBlockchainNetwork[newToken.contractAddress] {
                        if existingToken.id == nil, newToken.id != nil {
                            // Token has been saved without id, just updating this token
                            existingTokens[existingIndex] = newToken
                            hasChanges = true
                        }
                    } else {
                        // Token hasn't been added yet, just appending it to the end of the existing list
                        existingTokens.append(newToken)
                        hasChanges = true
                    }
                }
            }

            if hasChanges {
                save(existingTokens, forCardID: key)
            }
        }
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            let blockchainNetworks = blockchainNetworks.toSet()
            let existingItems = fetch(forCardID: key)
            var newItems = existingItems

            newItems.removeAll { blockchainNetworks.contains($0.blockchainNetwork) }

            let hasRemoved = newItems.count != existingItems.count
            if hasRemoved {
                save(newItems, forCardID: key)
            }
        }
    }

    func remove(_ tokens: [StorageEntry.V3.Entry], in blockchainNetwork: BlockchainNetwork) {
        lockQueue.sync {
            let contractAddresses = tokens.map(\.contractAddress).toSet() // may contain `nil` element
            let existingItems = fetch(forCardID: key)
            var newItems = existingItems

            newItems.removeAll { $0.blockchainNetwork == blockchainNetwork && contractAddresses.contains($0.contractAddress) }

            let hasRemoved = newItems.count != existingItems.count
            if hasRemoved {
                save(newItems, forCardID: key)
            }
        }
    }

    func removeAll() {
        lockQueue.sync {
            save([], forCardID: key)
        }
    }

    func getItems() -> [StorageEntry.V3.Entry] {
        lockQueue.sync {
            return fetch(forCardID: key)
        }
    }
}

// MARK: - Private

private extension _CommonTokenItemsRepository {
    func fetch(forCardID cardID: String) -> [StorageEntry.V3.Entry] {
        if let cachedItems = cache {
            return cachedItems
        }

        let tokens: [StorageEntry.V3.Entry] = (try? persistanceStorage.value(for: .wallets(cid: cardID))) ?? []
        cache = tokens

        return tokens
    }

    func save(_ tokens: [StorageEntry.V3.Entry], forCardID cardID: String) {
        markCacheAsDirty()

        do {
            try persistanceStorage.store(value: tokens, for: .wallets(cid: cardID))
        } catch {
            assertionFailure("\(objectDescription(self)) saving error: \(error)")
        }
    }

    func markCacheAsDirty() {
        cache = nil
    }
}
