//
//  OnrampQuotesRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampQuotesRequest: Hashable {
    public let pair: OnrampPair
    public let providerId: String
    public let paymentMethod: OnrampPaymentMethod
    public let amount: Decimal

    public init(
        pair: OnrampPair,
        providerId: String,
        paymentMethod: OnrampPaymentMethod,
        amount: Decimal
    ) {
        self.pair = pair
        self.providerId = providerId
        self.paymentMethod = paymentMethod
        self.amount = amount
    }
}
