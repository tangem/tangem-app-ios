//
//  CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct BlockchainSdk.Token

@available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
final class CommonTokenItemsRepository {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonTokenItemsRepository.lockQueue")
    private let key: String

    init(key: String) {
        self.key = key

        lockQueue.async { [weak self] in self?.migrate() }
    }

    deinit {
        AppLogger.debug(self, "deinit")
    }
}

// MARK: - TokenItemsRepository

extension CommonTokenItemsRepository: TokenItemsRepository {
    var containsFile: Bool {
        lockQueue.sync {
            let list: StoredUserTokenList? = try? persistentStorage.value(for: .wallets(cid: key))
            return list != nil
        }
    }

    func update(_ list: StoredUserTokenList) {
        lockQueue.sync {
            save(list)
        }
    }

    func getList() -> StoredUserTokenList {
        lockQueue.sync {
            return fetch()
        }
    }
}

// MARK: - Private

private extension CommonTokenItemsRepository {
    func migrate() {
        let legacyStorageEntries: [LegacyStorageEntry]? = try? persistentStorage.value(for: .wallets(cid: key))

        guard let legacyStorageEntries = legacyStorageEntries?.nilIfEmpty else { return }

        let converter = LegacyStorageEntriesConverter()
        let convertedStorageEntries: [StoredUserTokenList.Entry] = legacyStorageEntries
            .reduce(into: []) { partialResult, element in
                let blockchainNetwork = element.blockchainNetwork

                partialResult.append(converter.convertToStorageEntry(blockchainNetwork))
                partialResult += element.tokens.map { converter.convertToStorageEntry($0, in: blockchainNetwork) }
            }
        let storageEntriesList = StoredUserTokenList(
            entries: convertedStorageEntries,
            grouping: StoredUserTokenList.empty.grouping,
            sorting: StoredUserTokenList.empty.sorting
        )

        save(storageEntriesList)
    }

    func fetch() -> StoredUserTokenList {
        return (try? persistentStorage.value(for: .wallets(cid: key))) ?? .empty
    }

    func save(_ items: StoredUserTokenList) {
        do {
            try persistentStorage.store(value: items, for: .wallets(cid: key))
        } catch {
            assertionFailure("TokenItemsRepository saving error \(error)")
        }
    }
}

extension CommonTokenItemsRepository: CustomStringConvertible {
    var description: String { objectDescription(self) }
}

// MARK: - Legacy storage

/// Same as `StorageEntry`.
private struct LegacyStorageEntry: Decodable, Hashable {
    let blockchainNetwork: BlockchainNetwork
    let tokens: [BlockchainSdk.Token]
}

private struct LegacyStorageEntriesConverter {
    func convertToStorageEntry(
        _ blockchainNetwork: BlockchainNetwork
    ) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
            id: blockchainNetwork.blockchain.coinId,
            name: blockchainNetwork.blockchain.displayName,
            symbol: blockchainNetwork.blockchain.currencySymbol,
            decimalCount: blockchainNetwork.blockchain.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: nil
        )
    }

    func convertToStorageEntry(
        _ token: BlockchainSdk.Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
            id: token.id,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: token.contractAddress
        )
    }
}
