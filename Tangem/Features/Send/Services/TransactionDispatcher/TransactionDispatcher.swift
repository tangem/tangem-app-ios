//
//  TransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol TransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> TransactionDispatcherResult
    func send(transactions: [SendTransactionType]) async throws -> [TransactionDispatcherResult]
}

extension TransactionDispatcher {
    func send(transactions: [SendTransactionType]) async throws -> [TransactionDispatcherResult] {
        var results = [TransactionDispatcherResult]()
        for transaction in transactions {
            results.append(try await send(transaction: transaction))
        }

        return results
    }
}

struct TransactionDispatcherResult: Hashable {
    let hash: String
    let url: URL?
    let signerType: String
}

extension TransactionDispatcherResult {
    enum Error {
        case informationRelevanceServiceError
        case informationRelevanceServiceFeeWasIncreased

        case transactionNotFound
        case userCancelled
        case loadTransactionInfo(error: UniversalError)
        case sendTxError(transaction: SendTransactionType, error: SendTxError)

        case demoAlert
        case actionNotSupported

        var errorDescription: String? {
            switch self {
            case .sendTxError(_, let error):
                return error.localizedDescription
            case .loadTransactionInfo(let error):
                return error.localizedDescription
            case .demoAlert:
                return "Demo mode"
            case .informationRelevanceServiceError:
                return "Service error"
            case .informationRelevanceServiceFeeWasIncreased:
                return "Fee was increased"
            case .transactionNotFound:
                return "Transaction not found"
            case .userCancelled:
                return "User cancelled"
            case .actionNotSupported:
                return "Action not supported"
            }
        }
    }
}
