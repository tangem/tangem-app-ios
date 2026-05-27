//
//  OnrampQuote.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampQuote: Hashable {
    public let expectedAmount: Decimal
    public let nativePaymentAvailable: Bool
    public let quoteId: String?
}
