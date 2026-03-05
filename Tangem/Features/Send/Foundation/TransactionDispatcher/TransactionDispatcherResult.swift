//
//  TransactionDispatcherResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct TransactionDispatcherResult: Hashable {
    let hash: String
    /// Explorer url
    let url: URL?
    let signerType: String
    let currentHost: String
}

extension TransactionDispatcherResult {
    enum Error: CancellableError {
        case informationRelevanceServiceError
        case informationRelevanceServiceFeeWasIncreased

        case transactionNotFound
        case userCancelled
        case loadTransactionInfo(error: UniversalError)
        case sendTxError(transaction: TransactionDispatcherTransactionType, error: SendTxError)

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

        var isUserCancelled: Bool {
            switch self {
            case .userCancelled:
                return true
            default:
                return false
            }
        }
    }
}
