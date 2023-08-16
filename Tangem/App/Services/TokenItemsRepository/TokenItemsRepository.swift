//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ entries: [StorageEntry.V2.Entry])
    func append(_ entries: [StorageEntry.V2.Entry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork)
    func removeAll()

    func getItems() -> [StorageEntry.V2.Entry]
}
