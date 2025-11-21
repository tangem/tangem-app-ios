//
//  UserTokenListManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct UserTokenListManagerMock: UserTokenListManager {
    var initializedPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokensList: StoredUserTokenList { .empty }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { .just(output: .empty) }

    func update(with userTokenList: StoredUserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func upload() {}
}
