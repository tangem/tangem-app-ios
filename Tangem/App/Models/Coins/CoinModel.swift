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

struct CoinModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let items: [TokenItem]
}
