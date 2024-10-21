//
//  AdaliteResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct AdaliteUnspentOutput {
    let id: String
    let index: Int
}

public struct AdaliteBalanceResponse {
    let transactions: [String]
}
