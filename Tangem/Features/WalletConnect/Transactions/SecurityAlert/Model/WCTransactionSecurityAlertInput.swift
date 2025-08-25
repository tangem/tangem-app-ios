//
//  WCTransactionSecurityAlertInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WCTransactionSecurityAlertInput {
    let validationStatus: BlockaidChainScanResult.ValidationStatus
    let validationDescription: String?
    let primaryAction: () -> Void
    let secondaryAction: () async -> Void
    let backAction: () -> Void
}

extension WCTransactionSecurityAlertInput: Equatable {
    static func == (lhs: WCTransactionSecurityAlertInput, rhs: WCTransactionSecurityAlertInput) -> Bool {
        return lhs.validationStatus == rhs.validationStatus
    }
}
