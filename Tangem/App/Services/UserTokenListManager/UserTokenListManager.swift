//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import struct BlockchainSdk.Token
import struct TangemSdk.Card

protocol UserTokenListManager {
    /// If in result card not nil should update cardModel
    func append(entries: [StorageEntry], result: @escaping (Result<Card?, Error>) -> Void)
    func remove(blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void)
    func remove(tokens: [Token], in blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void)

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
    func syncGetEntriesFromRepository() -> [StorageEntry]
    func clearRepository(result: @escaping (Result<Void, Error>) -> Void)
}
