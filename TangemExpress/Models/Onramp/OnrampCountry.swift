//
//  OnrampCountry.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampCountry: Hashable {
    public let identity: OnrampIdentity
    public let currency: OnrampFiatCurrency
    public let onrampAvailable: Bool
}

extension OnrampCountry: Identifiable {
    public var id: OnrampIdentity {
        identity
    }
}
