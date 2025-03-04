//
//  TransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

// Will be supported in BTC-like / Fact0rn / Radiant and etc.
protocol TransactionRecordMapper {
    associatedtype Transaction
    func mapToTransactionRecord(transaction: Transaction, address: String) throws -> TransactionRecord
}

enum TransactionRecordMapperError: LocalizedError {
    case valueNotFound(String)

    var errorDescription: String? {
        switch self {
        case .valueNotFound(let value): "Value not found: \(value)"
        }
    }
}
