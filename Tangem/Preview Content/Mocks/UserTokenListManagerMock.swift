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
    var userTokens: [StorageEntry] {
        []
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        .just(output: [])
    }

    var userTokenList: any Publisher<UserTokenList, Never> {
        fatalError("\(#function) not implemented yet ([REDACTED_INFO])")
    }

    func update(with userTokenList: UserTokenList) {
        fatalError("\(#function) not implemented yet ([REDACTED_INFO])")
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {}

    func upload() {}
}
