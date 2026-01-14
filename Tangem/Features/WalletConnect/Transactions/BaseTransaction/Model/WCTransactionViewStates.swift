//
//  WCTransactionViewStates.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension WCTransactionViewModel {
    enum ViewAction {
        case dismissTransactionView
        case cancel
        case sign
        case returnTransactionDetails
        case showRequestData
        case showFeeSelector
        case editApproval(ApprovalInfo, BlockaidChainScanResult.Asset)
    }

    enum PresentationState: Equatable {
        case signing
        case transactionDetails
        case requestData(WCRequestDetailsInput)
        case feeSelector(WCFeeSelectorContentViewModel)
        case customAllowance(WCCustomAllowanceViewModel)
        case securityAlert(WCTransactionSecurityAlertViewModel)
        case multipleTransactionsAlert(WCMultipleTransactionAlertViewModel)
        case loading

        var stateId: String {
            switch self {
            case .signing:
                return "signing"
            case .transactionDetails:
                return "transactionDetails"
            case .requestData:
                return "requestData"
            case .feeSelector:
                return "feeSelector"
            case .customAllowance:
                return "customAllowance"
            case .securityAlert:
                return "securityAlert"
            case .multipleTransactionsAlert:
                return "multipleTransactionsAlert"
            case .loading:
                return "loading"
            }
        }

        static func == (lhs: PresentationState, rhs: PresentationState) -> Bool {
            switch (lhs, rhs) {
            case (.signing, .signing),
                 (.transactionDetails, .transactionDetails),
                 (.multipleTransactionsAlert, .multipleTransactionsAlert),
                 (.loading, .loading):
                return true
            case (.requestData(let lhsInput), .requestData(let rhsInput)):
                return lhsInput == rhsInput
            case (.feeSelector(let lhsViewModel), .feeSelector(let rhsViewModel)):
                return lhsViewModel.id == rhsViewModel.id
            case (.customAllowance(let lhsViewModel), .customAllowance(let rhsViewModel)):
                return lhsViewModel.id == rhsViewModel.id
            case (.securityAlert(let lhsViewModel), .securityAlert(let rhsViewModel)):
                return lhsViewModel == rhsViewModel
            default:
                return false
            }
        }
    }
}
