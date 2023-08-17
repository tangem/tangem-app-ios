//
//  StorageEntry.V3.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry {
    enum V3 {
        typealias BlockchainNetwork = Tangem.BlockchainNetwork

        enum Grouping: Codable, Equatable {
            case none
            case byBlockchainNetwork
        }

        enum Sorting: Codable, Equatable {
            case manual
            case byBalance
        }

        struct Entry: Codable, Equatable {
            let id: String?
            let networkId: String
            let name: String
            let symbol: String
            let decimals: Int
            let blockchainNetwork: BlockchainNetwork
            let contractAddress: String?
        }

        struct List: Codable, Equatable {
            var grouping: Grouping
            var sorting: Sorting
            var entries: [Entry]
        }
    }
}
