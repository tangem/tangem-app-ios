//
//  UserTokenListUpdateType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

enum UserTokenListUpdateType {
    case append(_ entries: [TokenItem])
    case remove(_ entry: TokenItem)
    case update(_ request: UserTokensRepositoryUpdateRequest)
}
