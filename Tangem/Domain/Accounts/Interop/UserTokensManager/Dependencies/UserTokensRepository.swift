//
//  UserTokensRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
protocol UserTokensRepository {
    typealias Completion = (Result<Void, Swift.Error>) -> Void

    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> { get }
    var cryptoAccount: StoredCryptoAccount { get }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func update(with request: UserTokensRepositoryUpdateRequest)
    func updateLocalRepositoryFromServer(_ completion: @escaping Completion)
    func upload()
}
