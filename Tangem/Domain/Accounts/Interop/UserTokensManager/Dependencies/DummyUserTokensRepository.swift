//
//  DummyUserTokensRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
struct DummyUserTokensRepository: UserTokensRepository {
    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> { .just(output: cryptoAccount) }
    var cryptoAccount: StoredCryptoAccount { StoredCryptoAccount(config: AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: .init(value: .randomData(count: 20)))) }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func update(with request: UserTokensRepositoryUpdateRequest) {}

    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        completion(.success(()))
    }

    func upload() {}
}
