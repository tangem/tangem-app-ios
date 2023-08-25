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
    case append(_ entries: [StorageEntry])
    case removeBlockchain(_ blockchainNetwork: BlockchainNetwork)
    case removeToken(_ token: Token, in: BlockchainNetwork)
    case group(_ groupingOption: StorageEntry.V3.Grouping)
    case sort(_ sortingOption: StorageEntry.V3.Sorting)
}
