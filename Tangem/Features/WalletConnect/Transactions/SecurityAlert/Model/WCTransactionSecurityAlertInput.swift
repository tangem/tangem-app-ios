//
//  WCTransactionSecurityAlertInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WCTransactionSecurityAlertInput {
    let validationStatus: BlockaidChainScanResult.ValidationStatus
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let closeAction: () -> Void
}
