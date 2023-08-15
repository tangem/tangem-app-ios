//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]
protocol UserTokenListManager: UserTokensSyncService {
    var userTokens: [StorageEntry.V3.Entry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> { get }
    var userTokenList: AnyPublisher<UserTokenList, Never> { get }

    func update(with userTokenList: UserTokenList)
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    func upload()
}
