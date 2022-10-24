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
    func update(_ type: CommonUserTokenListManager.UpdateType, completion: @escaping () -> Void)

    func updateLocalRepositoryFromServer(result: @escaping (Result<UserTokenList, Error>) -> Void)
    func getEntriesFromRepository() -> [StorageEntry]
    func clearRepository(completion: @escaping () -> Void)
}
