//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ list: StorageEntriesList)
    func append(_ entries: [StorageEntriesList.Entry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ entries: [StorageEntriesList.Entry])
    func removeAll()

    func getList() -> StorageEntriesList
}
