//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol UserTokenListManager: UserTokensSyncService {
    var userTokens: [StorageEntry.V3.Entry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> { get }

    var groupingOptionPublisher: AnyPublisher<StorageEntry.V3.Grouping, Never> { get }
    var sortingOptionPublisher: AnyPublisher<StorageEntry.V3.Sorting, Never> { get }

    func update(_ updates: [UserTokenListUpdateType], shouldUpload: Bool)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    func updateServerFromLocalRepository()
}

// MARK: - Convenience extensions

extension UserTokenListManager {
    func update(_ updates: UserTokenListUpdateType..., shouldUpload: Bool) {
        update(updates, shouldUpload: shouldUpload)
    }
}
