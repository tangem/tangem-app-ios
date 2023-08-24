//
//  StorageEntriesList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_USERNAME](*, deprecated, message: "Get rid of this temporary alias and rename StorageEntriesList")
typealias StoredUserTokenList = StorageEntriesList

// [REDACTED_TODO_COMMENT]
struct StorageEntriesList: Codable, Equatable {
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
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetwork
        let contractAddress: String?
    }

    let entries: [Entry]
    let grouping: Grouping
    let sorting: Sorting
}

// MARK: - Convenience extensions

extension StorageEntriesList {
    static var empty: Self { Self(entries: [], grouping: .none, sorting: .manual) }
}

extension StorageEntriesList.Entry {
    var isToken: Bool { contractAddress != nil }
    var isCustom: Bool { id == nil }
}
