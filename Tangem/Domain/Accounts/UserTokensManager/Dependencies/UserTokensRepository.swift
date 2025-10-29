//
//  UserTokensRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserTokensRepository {
    typealias Completion = (Result<Void, Swift.Error>) -> Void
    typealias BatchUpdates = (UserTokensRepositoryBatchUpdater) throws -> Void

    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> { get }
    var cryptoAccount: StoredCryptoAccount { get }

    func performBatchUpdates(_ batchUpdates: BatchUpdates) rethrows
    func updateLocalRepositoryFromServer(_ completion: @escaping Completion)
}
