//
//  OnrampHistoryRate.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryRate: Hashable {
    /// Crypto rate (in fiat) fixed when the order was created.
    public let atCreate: Decimal?
    /// Crypto rate (in fiat) recorded once the order completed.
    public let atFinish: Decimal?
}
