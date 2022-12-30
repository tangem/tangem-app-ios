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
    var didPerformInitialLoading: Bool { get }

    func update(userWalletId: Data)
    func update(_ type: CommonUserTokenListManager.UpdateType)

    func updateLocalRepositoryFromServer(result: @escaping (Result<UserTokenList, Error>) -> Void)
    func getEntriesFromRepository() -> [StorageEntry]
    func clearRepository(completion: @escaping () -> Void)
}
