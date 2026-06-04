//
//  SendOnrampNAPAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol SendOnrampNAPAnalyticsLogger {
    func logOnrampButtonNAP(amount: Decimal, currencyCode: String)
    func logOnrampNAPScreenOpened()
}
