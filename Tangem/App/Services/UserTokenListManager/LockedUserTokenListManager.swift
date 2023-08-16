//
//  LockedUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct LockedUserTokenListManager: UserTokenListManager {
    var isInitialSyncPerformed: Bool { false }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    var userTokens: [StorageEntry.V3.Entry] { [] }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> { .just(output: []) }

    var userTokenList: AnyPublisher<UserTokenList, Never> { .just(output: .empty) }

    func update(with userTokenList: UserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        result(.success(()))
    }

    func updateUserTokens() {}

    func upload() {}
}
