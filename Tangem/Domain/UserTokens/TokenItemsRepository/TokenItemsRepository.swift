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
@available(iOS, deprecated: 100000.0, message: "Will be removed after accounts migration is complete ([REDACTED_INFO])")
protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ list: StoredUserTokenList)
    func append(_ entries: [StoredUserTokenList.Entry])

    func remove(_ blockchainNetworks: [BlockchainNetwork], completion: (() -> Void)?)
    func remove(_ entries: [StoredUserTokenList.Entry])
    func removeAll()

    func getList() -> StoredUserTokenList
}
