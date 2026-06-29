//
//  TransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryMapper {
    associatedtype Response
    associatedtype WalletAddress

    func mapToTransactionRecords(
        _ response: Response,
        walletAddress: WalletAddress,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord]

    func reset()
}

// MARK: - Default implementation

extension TransactionHistoryMapper {
    func reset() {}
}

// MARK: - Error

extension TransactionHistory {
    enum MapperError: LocalizedError {
        case notFound(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let message): 
                "\(message) not found"
            }
        }
    }
}
