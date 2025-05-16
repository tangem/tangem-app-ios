//
//  VisaTokenListManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class VisaTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry] { [] }
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { Just([]).eraseToAnyPublisher() }
    var userTokensList: StoredUserTokenList {
        .init(entries: [], grouping: .none, sorting: .byBalance)
    }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> {
        Just(userTokensList).eraseToAnyPublisher()
    }

    var initialized: Bool = true
    var initializedPublisher: AnyPublisher<Bool, Never> { Just(true).eraseToAnyPublisher() }

    func update(with userTokenList: StoredUserTokenList) {}
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}
    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, any Error>) -> Void) {}
    func upload() {}
}
