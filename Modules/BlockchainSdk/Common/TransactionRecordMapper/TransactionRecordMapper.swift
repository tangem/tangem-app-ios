//
//  TransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Will be supported in BTC-like / Fact0rn / Radiant and etc.
protocol TransactionRecordMapper {
    associatedtype Transaction
    func mapToTransactionRecord(transaction: Transaction, address: String) throws -> TransactionRecord
}
