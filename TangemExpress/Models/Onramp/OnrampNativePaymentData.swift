//
//  OnrampNativePaymentData.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampNativePaymentData {
    public let txId: String
    public let fromAmount: Decimal
    public let fromCurrencyCode: String
    public let externalTxId: String?
    public let externalTxURL: URL?
}
