//
//  TransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public protocol TransactionHistoryProvider: CustomStringConvertible {
    var canFetchHistory: Bool { get }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error>
    func shouldBeIncludedInHistory(amountType: Amount.AmountType, record: TransactionRecord) -> Bool
    func reset()
}

// MARK: - Default implementation

public extension TransactionHistoryProvider {
    func shouldBeIncludedInHistory(amountType: Amount.AmountType, record: TransactionRecord) -> Bool {
        switch amountType {
        case .coin where record.type == .transfer:
            break
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            break
        }

        switch record.destination {
        case .single(let destination):
            return destination.amount != 0
        case .multiple(let destinations):
            return destinations.contains { $0.amount != 0 }
        }
    }
}

// MARK: - Error

public extension TransactionHistory {
    enum ProviderError: LocalizedError {
        case requestKeyNotSupported

        public var errorDescription: String? {
            switch self {
            case .requestKeyNotSupported:
                "Request key is not supported by this provider"
            }
        }
    }
}
