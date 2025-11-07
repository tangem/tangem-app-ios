//
//  WCMultipleTransactionAlertInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCMultipleTransactionAlertInput {
    let primaryAction: () async throws -> Void
    let secondaryAction: () -> Void
    let backAction: () -> Void
}
