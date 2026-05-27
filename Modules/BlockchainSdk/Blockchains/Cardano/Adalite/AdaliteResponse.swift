//
//  AdaliteResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct AdaliteUnspentOutput {
    let id: String
    let index: Int
}

struct AdaliteBalanceResponse {
    let transactions: [String]
}
