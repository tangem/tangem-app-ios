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

    func update(_ entries: [StorageEntry])
    func append(_ entries: [StorageEntry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork)
    func removeAll()

    func getItems() -> [StorageEntry]
}
