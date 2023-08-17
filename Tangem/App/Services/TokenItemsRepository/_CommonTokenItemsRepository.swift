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

    /// - Warning: MUST BE called only AFTER the storage migration has been attempted,
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

    func update(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            save(entries, forCardID: key)
        }
    }

    func append(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            var existingEntries = fetch()
            var hasChanges = false
            var existingBlockchainNetworksToUpdate: [StorageEntry.V3.BlockchainNetwork] = []

            let existingEntriesWithIndicesGroupedByBlockchainNetworks = Dictionary(
                grouping: existingEntries.enumerated(),
                by: \.element.blockchainNetwork
            )

            let newEntriesGroupedByBlockchainNetworks = Dictionary(grouping: entries, by: \.blockchainNetwork)
            let newBlockchainNetworks = entries.unique(by: \.blockchainNetwork).map(\.blockchainNetwork)

            for newBlockchainNetwork in newBlockchainNetworks {
                if existingEntriesWithIndicesGroupedByBlockchainNetworks[newBlockchainNetwork] != nil {
                    // This blockchain network already exists, and it probably needs to be updated with new tokens
                    existingBlockchainNetworksToUpdate.append(newBlockchainNetwork)
                } else if let newEntries = newEntriesGroupedByBlockchainNetworks[newBlockchainNetwork] {
                    // New network, just appending all tokens from it to the end of the existing list
                    existingEntries.append(contentsOf: newEntries)
                    hasChanges = true
                }
            }

            for blockchainNetwork in existingBlockchainNetworksToUpdate {
                guard
                    let existingEntriesForBlockchainNetwork = existingEntriesWithIndicesGroupedByBlockchainNetworks[blockchainNetwork],
                    let newEntriesForBlockchainNetwork = newEntriesGroupedByBlockchainNetworks[blockchainNetwork]
                else {
                    continue
                }
                
                let blockchainNetworkHasBeenUpdated = updateEntries(
                    &existingEntries,
                    in: blockchainNetwork,
                    existingEntriesWithIndices: existingEntriesForBlockchainNetwork,
                    newEntries: newEntriesForBlockchainNetwork
                )
                if blockchainNetworkHasBeenUpdated {
                    hasChanges = true
                }
            }

            if hasChanges {
                save(existingEntries, forCardID: key)
            }
        }
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            let blockchainNetworks = blockchainNetworks.toSet()
            let existingEntries = fetch()
            var newEntries = existingEntries

            newEntries.removeAll { blockchainNetworks.contains($0.blockchainNetwork) }

            let hasRemoved = newEntries.count != existingEntries.count
            if hasRemoved {
                save(newEntries, forCardID: key)
            }
        }
    }

    func remove(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            let deletedEntriesKeys = entries
                .map { StorageEntryKey(blockchainNetwork: $0.blockchainNetwork, contractAddresses: $0.contractAddress) }
                .toSet()

            let existingEntries = fetch()
            var newEntries = existingEntries

            newEntries.removeAll { entry in
                let key = StorageEntryKey(blockchainNetwork: entry.blockchainNetwork, contractAddresses: entry.contractAddress)
                return deletedEntriesKeys.contains(key)
            }

            let hasRemoved = newEntries.count != existingEntries.count
            if hasRemoved {
                save(newEntries, forCardID: key)
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
            return fetch()
        }
    }
}

// MARK: - Private

private extension _CommonTokenItemsRepository {
    func fetch() -> [StorageEntry.V3.Entry] {
        if let cachedEntries = cache {
            return cachedEntries
        }

        let entries: [StorageEntry.V3.Entry] = (try? persistanceStorage.value(for: .wallets(cid: key))) ?? []
        cache = entries

        return entries
    }

    func save(_ entries: [StorageEntry.V3.Entry], forCardID cardID: String) {
        if cardID == key {
            markCacheAsDirty()
        }

        do {
            try persistanceStorage.store(value: entries, for: .wallets(cid: cardID))
        } catch {
            assertionFailure("\(objectDescription(self)) saving error: \(error)")
        }
    }

    func markCacheAsDirty() {
        cache = nil
    }

    func updateEntries(
        _ entriesToUpdate: inout [StorageEntry.V3.Entry],
        in blockchainNetworkToUpdate: BlockchainNetwork,
        existingEntriesWithIndices: [(Int, StorageEntry.V3.Entry)],
        newEntries: [StorageEntry.V3.Entry]
    ) -> Bool {
        // `contractAddress` may be `nil`, this is a valid key
        let existingEntriesWithIndicesKeyedByContractAddress = existingEntriesWithIndices.keyedFirst(by: \.1.contractAddress)
        var hasChanges = false

        for newEntry in newEntries {
            if let (existingIndex, existingEntry) = existingEntriesWithIndicesKeyedByContractAddress[newEntry.contractAddress] {
                if existingEntry.id == nil, newEntry.id != nil {
                    // Entry has been saved without id, just updating this entry
                    entriesToUpdate[existingIndex] = newEntry   // upgrading custom token
                    hasChanges = true
                }
            } else {
                // Token hasn't been added yet, just appending it to the end of the existing list
                entriesToUpdate.append(newEntry)
                hasChanges = true
            }
        }

        return hasChanges
    }
}

// MARK: - Auxiliary types

private extension _CommonTokenItemsRepository {
    /// A key for fast O(1) lookups in sets, dictionaries, etc.
    struct StorageEntryKey: Hashable {
        let blockchainNetwork: StorageEntry.V3.BlockchainNetwork
        let contractAddresses: String?
    }
}
