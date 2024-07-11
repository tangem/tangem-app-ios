//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum SendType {
    case send
    case sell(parameters: PredefinedSellParameters)
}

struct PredefinedSellParameters {
    let amount: Decimal
    let destination: String
    let tag: String?
}
