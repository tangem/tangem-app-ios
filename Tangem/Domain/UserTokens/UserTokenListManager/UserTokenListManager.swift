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
@available(iOS, deprecated: 100000.0, message: "Will be removed after accounts migration is complete ([REDACTED_INFO])")
protocol UserTokenListManager {
    var initializedPublisher: AnyPublisher<Bool, Never> { get }

    var userTokensList: StoredUserTokenList { get }
    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { get }

    func update(with userTokenList: StoredUserTokenList)
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, Error>) -> Void)
    func upload()
}
