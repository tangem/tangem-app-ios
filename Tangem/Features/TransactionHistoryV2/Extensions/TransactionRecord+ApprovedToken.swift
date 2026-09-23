//
//  TransactionRecord+ApprovedToken.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension TransactionRecord {
    var approvedTokenContract: String? {
        guard
            case .approve = type,
            case .single(let destination) = destination,
            case .contract(let contract) = destination.address
        else {
            return nil
        }

        return contract
    }
}
