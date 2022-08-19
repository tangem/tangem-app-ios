//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol UserTokenListManager {
    func append(entry: [StorageEntry], completion: (Result<Void, Error>) -> Void)
    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
}

extension UserTokenListManager {
    func append(entry: [StorageEntry], completion: (Result<Void, Error>) -> Void = { _ in }) {
        append(entry: entry, completion: completion)
    }
}
