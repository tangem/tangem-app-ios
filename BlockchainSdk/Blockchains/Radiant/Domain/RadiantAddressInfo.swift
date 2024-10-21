//
//  RadiantAddressInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantAddressInfo {
    let balance: Decimal
    let outputs: [ElectrumUTXO]
}
