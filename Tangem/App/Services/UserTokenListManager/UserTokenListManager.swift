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
    // var didPerformInitialLoading: Bool { get }
    var userTokens: [StorageEntry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { get }

    func contains(_ entry: StorageEntry) -> Bool
    func update(_ type: CommonUserTokenListManager.UpdateType)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    // func getEntriesFromRepository() -> [StorageEntry]
    // func clearRepository(completion: @escaping () -> Void)
}
