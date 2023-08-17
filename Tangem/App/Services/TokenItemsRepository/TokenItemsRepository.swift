//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenItemsRepository: AnyObject {
    var isInitialized: Bool { get }
    var groupingOption: StorageEntry.V3.Grouping { get set }
    var sortingOption: StorageEntry.V3.Sorting { get set }

    func update(_ tokens: [StorageEntry.V3.Entry])
    func append(_ tokens: [StorageEntry.V3.Entry])
    func remove(_ tokens: [StorageEntry.V3.Entry])
    func remove(_ blockchainNetworks: [StorageEntry.V3.BlockchainNetwork])
    func removeAll()

    func getItems() -> [StorageEntry.V3.Entry]
}
