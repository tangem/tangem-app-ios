//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

@available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ list: StoredUserTokenList)

    func getList() -> StoredUserTokenList
}
