//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol UserTokenListManager {
    func append(entries: [StorageEntry], result: @escaping (Result<Void, Error>) -> Void)
    func remove(blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void)
    func remove(tokens: [Token], in blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void)

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
    func syncGetEntriesFromRepository() -> [StorageEntry]
    func clearRepository(result: @escaping (Result<Void, Error>) -> Void)
}

extension UserTokenListManager {
    func append(entries: [StorageEntry]) {
        append(entries: entries, result: { _ in })
    }

    func append(networks: [BlockchainNetwork], result: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        let entries = networks.map { StorageEntry(blockchainNetwork: $0, tokens: []) }
        append(entries: entries, result: result)
    }
}
