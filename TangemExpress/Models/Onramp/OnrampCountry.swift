//
//  OnrampCountry.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampCountry: Hashable {
    public let identity: OnrampIdentity
    public let currency: OnrampCurrency
    public let onrampAvailable: Bool

    public init(identity: OnrampIdentity, currency: OnrampCurrency, onrampAvailable: Bool) {
        self.identity = identity
        self.currency = currency
        self.onrampAvailable = onrampAvailable
    }
}
