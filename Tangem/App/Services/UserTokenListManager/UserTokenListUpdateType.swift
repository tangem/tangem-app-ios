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
//    case rewrite(_ entries: [StorageEntry])   // isn't used at all
    case append(_ entries: [StorageEntry])
    case removeBlockchain(_ blockchain: BlockchainNetwork) // this is not a damn blockchain!
    case removeToken(_ token: Token, in: BlockchainNetwork)
}
