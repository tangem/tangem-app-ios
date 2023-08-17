//
//  CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CommonTokenItemsRepository {
    @Injected(\.persistentStorage) private var persistanceStorage: PersistentStorageProtocol

    @AppStorageCompat(StorageKeys.currentStorageVersion)
    private var currentStorageVersion: StorageEntry.Version = .v3

    private var actualStorageVersion: StorageEntry.Version { .v3 }

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonTokenItemsRepository.lockQueue")
    private let key: String
    private var cache: StorageEntry.V3.List?

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
            cardID: key
        ) { entries, cardID in
            self.save(entries, to: \.entries, forCardID: cardID)
        }
        migrator.migrate(from: currentStorageVersion, to: actualStorageVersion)
    }

    /// - Warning: MUST BE called only AFTER the storage migration has been attempted,
    /// otherwise user data may be lost.
    private func updateCurrentStorageVersion() {
        currentStorageVersion = actualStorageVersion
    }
}

// MARK: - Constants

private extension CommonTokenItemsRepository {
    enum StorageKeys: String {
        case currentStorageVersion = "com.tangem.CommonTokenItemsRepository.currentStorageVersion"
    }
}

// MARK: - TokenItemsRepository protocol conformance

extension CommonTokenItemsRepository: TokenItemsRepository {
    var isInitialized: Bool {
        lockQueue.sync {
            // Here it's necessary to distinguish between empty (`[]` value) and non-initialized
            // (`nil` value) storage, therefore direct access to the underlying storage is used here
            let entries: [StorageEntry.V3.Entry]? = try? persistanceStorage.value(for: .wallets(cid: key))
            return entries != nil
        }
    }

    var groupingOption: StorageEntry.V3.Grouping {
        get {
            return lockQueue.sync {
                fetch().grouping
            }
        }
        set {
            lockQueue.sync {
                save(newValue, to: \.grouping, forCardID: key)
            }
        }
    }

    var sortingOption: StorageEntry.V3.Sorting {
        get {
            return lockQueue.sync {
                fetch().sorting
            }
        }
        set {
            lockQueue.sync {
                save(newValue, to: \.sorting, forCardID: key)
            }
        }
    }

    func update(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            save(entries, to: \.entries, forCardID: key)
        }
    }

    func append(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            var existingEntries = fetch().entries
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
                save(existingEntries, to: \.entries, forCardID: key)
            }
        }
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            let blockchainNetworks = blockchainNetworks.toSet()
            let existingEntries = fetch().entries
            var newEntries = existingEntries

            newEntries.removeAll { blockchainNetworks.contains($0.blockchainNetwork) }

            let hasRemoved = newEntries.count != existingEntries.count
            if hasRemoved {
                save(newEntries, to: \.entries, forCardID: key)
            }
        }
    }

    func remove(_ entries: [StorageEntry.V3.Entry]) {
        lockQueue.sync {
            let deletedEntriesKeys = entries
                .map { StorageEntryKey(blockchainNetwork: $0.blockchainNetwork, contractAddresses: $0.contractAddress) }
                .toSet()

            let existingEntries = fetch().entries
            var newEntries = existingEntries

            newEntries.removeAll { entry in
                let key = StorageEntryKey(blockchainNetwork: entry.blockchainNetwork, contractAddresses: entry.contractAddress)
                return deletedEntriesKeys.contains(key)
            }

            let hasRemoved = newEntries.count != existingEntries.count
            if hasRemoved {
                save(newEntries, to: \.entries, forCardID: key)
            }
        }
    }

    func removeAll() {
        lockQueue.sync {
            save([], to: \.entries, forCardID: key)
        }
    }

    func getItems() -> [StorageEntry.V3.Entry] {
        lockQueue.sync {
            return fetch().entries
        }
    }
}

// MARK: - Private

private extension CommonTokenItemsRepository {
    func fetch() -> StorageEntry.V3.List {
        if let cachedList = cache {
            return cachedList
        }

        let list: StorageEntry.V3.List = (try? persistanceStorage.value(for: .wallets(cid: key))) ?? .empty
        cache = list

        return list
    }

    func save<T>(
        _ value: T,
        to keyPath: WritableKeyPath<StorageEntry.V3.List, T>,
        forCardID cardID: String
    ) {
        let existingList = fetch()
        var updatedList = existingList
        updatedList[keyPath: keyPath] = value

        guard existingList != updatedList else { return }

        if cardID == key {
            markCacheAsDirty()
        }

        do {
            try persistanceStorage.store(value: updatedList, for: .wallets(cid: cardID))
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

// MARK: - Convenience extensions

private extension StorageEntry.V3.List {
    static var empty: Self { Self(grouping: .none, sorting: .manual, entries: []) }
}

// MARK: - Auxiliary types

private extension CommonTokenItemsRepository {
    /// A key for fast O(1) lookups in sets, dictionaries, etc.
    struct StorageEntryKey: Hashable {
        let blockchainNetwork: StorageEntry.V3.BlockchainNetwork
        let contractAddresses: String?
    }
}
