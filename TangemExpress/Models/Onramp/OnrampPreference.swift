//
//  OnrampPreference.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPreference: Hashable {
    public let country: OnrampCountry?
    public let currency: OnrampFiatCurrency?
}

public extension OnrampPreference {
    var isEmpty: Bool {
        country == nil && currency == nil
    }
}
