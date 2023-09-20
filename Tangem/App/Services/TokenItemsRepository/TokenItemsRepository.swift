//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

// [REDACTED_TODO_COMMENT]
protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ list: StoredUserTokenList)
    func append(_ entries: [StoredUserTokenList.Entry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ entries: [StoredUserTokenList.Entry])
    func removeAll()

    func getList() -> StoredUserTokenList
}
