//
//  ExchangeStatusPollIteration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExchangeStatusPollIteration {
    let displayed: [PendingExpressTransaction]
    let changed: [ExpressPendingTransactionRecord]
    let polled: [ExchangeTransaction]
}
