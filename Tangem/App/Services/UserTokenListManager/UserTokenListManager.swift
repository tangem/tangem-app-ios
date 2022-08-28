//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import struct BlockchainSdk.Token

protocol UserTokenListManager {
    func update(userWalletId: String)

    /// If in result card not nil should update cardModel
    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void)
    func remove(blockchain: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void)
    func remove(tokens: [Token], in blockchain: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void)

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
    func syncGetEntriesFromRepository() -> [StorageEntry]
    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void)
}
