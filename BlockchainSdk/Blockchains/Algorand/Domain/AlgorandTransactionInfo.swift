//
//  AlgorandTransactionInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandTransactionInfo {
    let transactionHash: String?
    let status: Status
}

extension AlgorandTransactionInfo {
    enum Status: String {
        case committed
        case still
        case removed
    }
}
