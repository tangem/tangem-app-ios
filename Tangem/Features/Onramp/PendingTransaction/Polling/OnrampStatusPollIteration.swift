//
//  OnrampStatusPollIteration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampStatusPollIteration {
    let displayed: [PendingOnrampTransaction]
    let changed: [OnrampPendingTransactionRecord]
    let polled: [OnrampTransaction]
}
