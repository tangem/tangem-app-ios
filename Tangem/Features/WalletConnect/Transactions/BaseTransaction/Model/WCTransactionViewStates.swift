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
        case feeSelector(FeeSelectorContentViewModel)
        case customAllowance(WCCustomAllowanceInput)
        case securityAlert(state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput)

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
            }
        }

        static func == (lhs: PresentationState, rhs: PresentationState) -> Bool {
            switch (lhs, rhs) {
            case (.signing, .signing),
                 (.transactionDetails, .transactionDetails):
                return true
            case (.requestData(let lhsInput), .requestData(let rhsInput)):
                return lhsInput == rhsInput
            case (.feeSelector, .feeSelector):
                return true
            case (.customAllowance(let lhsInput), .customAllowance(let rhsInput)):
                return lhsInput == rhsInput
            case (.securityAlert(let lhsState, let lhsInput), .securityAlert(let rhsState, let rhsInput)):
                return lhsState == rhsState && lhsInput == rhsInput
            default:
                return false
            }
        }
    }
}
