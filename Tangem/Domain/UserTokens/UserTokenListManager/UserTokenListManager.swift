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
    typealias Completion = (Result<Void, Swift.Error>) -> Void

    @available(*, deprecated, message: "Get rid of this property")
    var userTokens: [StorageEntry] { get }
    @available(*, deprecated, message: "Get rid of this property")
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { get }

    @available(*, deprecated, message: "Get rid of this property")
    var userTokensList: StoredUserTokenList { get }
    @available(*, deprecated, message: "Get rid of this property")
    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { get }

    @available(*, deprecated, message: "Get rid of this property")
    func update(with userTokenList: StoredUserTokenList)
    @available(*, deprecated, message: "Get rid of this property")
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    @available(*, deprecated, message: "Get rid of this property")
    func updateLocalRepositoryFromServer(_ completion: @escaping Completion)
    @available(*, deprecated, message: "Get rid of this property")
    func upload()
}
