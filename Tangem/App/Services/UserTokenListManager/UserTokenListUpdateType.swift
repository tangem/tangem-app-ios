//
//  UserTokenListUpdateType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdkLocal.Token

enum UserTokenListUpdateType {
    case append(_ entries: [StorageEntry])
    case removeBlockchain(_ blockchainNetwork: BlockchainNetwork)
    case removeToken(_ token: Token, in: BlockchainNetwork)
}
