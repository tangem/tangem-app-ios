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
    func update(userWalletId: Data)
    func update(_ type: CommonUserTokenListManager.UpdateType, result: @escaping (Result<UserTokenList, Error>) -> Void)

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
    func getEntriesFromRepository() -> [StorageEntry]
    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void)
}
