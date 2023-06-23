//
//  UserTokenListManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokenListManagerMock: UserTokenListManager {
    var didPerformInitialLoading: Bool { false }

    func update(userWalletId: Data) {}

    func update(_ type: UserTokenListUpdateType) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<UserTokenList, Error>) -> Void) {}

    func getEntriesFromRepository() -> [StorageEntry] { [] }

    func clearRepository(completion: @escaping () -> Void) {}
}
