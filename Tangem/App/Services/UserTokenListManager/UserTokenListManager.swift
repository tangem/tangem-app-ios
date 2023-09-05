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
protocol UserTokenListManager: UserTokensSyncService {
    var userTokens: [StorageEntry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { get }

    var userTokensList: StoredUserTokenList { get }
    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { get }

    func update(with userTokenList: StoredUserTokenList)
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    func upload()
}
