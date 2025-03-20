//
//  PendingExpressTransactionParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct PendingExpressTransactionParams {
    let externalStatus: ExpressTransactionStatus
    let averageDuration: TimeInterval?
    let createdAt: Date?
}
