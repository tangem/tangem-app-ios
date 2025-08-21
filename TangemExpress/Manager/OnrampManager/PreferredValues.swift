//
//  PreferredValues.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct PreferredValues {
    public static let none = PreferredValues(paymentMethodType: .none, providerId: .none)

    public let paymentMethodType: OnrampPaymentMethod.MethodType?
    public let providerId: String?

    public init(paymentMethodType: OnrampPaymentMethod.MethodType? = nil, providerId: String? = nil) {
        self.paymentMethodType = paymentMethodType
        self.providerId = providerId
    }
}
