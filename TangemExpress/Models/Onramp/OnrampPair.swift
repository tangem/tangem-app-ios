//
//  OnrampPair.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPair: Hashable {
    public let fiatCurrencyCode: String?
    public let currency: ExpressCurrency
    public let providers: [OnrampProvider]

    public init(
        fiatCurrencyCode: String?,
        currency: ExpressCurrency,
        providers: [OnrampProvider]
    ) {
        self.fiatCurrencyCode = fiatCurrencyCode
        self.currency = currency
        self.providers = providers
    }
}
