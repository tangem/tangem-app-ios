//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

protocol TokenItemsRepository {
    func append(_ entries: [StorageEntry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork)
    func removeAll()

    func getItems() -> [StorageEntry]
}

extension TokenItemsRepository {
    func append(_ blockchainNetworks: [BlockchainNetwork]) {
        let entries = blockchainNetworks.map { StorageEntry(blockchainNetwork: $0, tokens: []) }
        append(entries)
    }

    func append(_ tokens: [Token], blockchainNetwork: BlockchainNetwork) {
        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
        append([entry])
    }
}
