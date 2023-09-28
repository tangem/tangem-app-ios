//
//  CoinModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

final class CoinModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let items: [TokenItem]

    // MARK: - Init

    init(id: String, name: String, symbol: String, items: [TokenItem]) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.items = items
    }
}
