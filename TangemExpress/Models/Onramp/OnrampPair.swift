//
//  OnrampPair.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPairRequestItem {
    public let fiatCurrency: OnrampFiatCurrency
    public let country: OnrampCountry
    public let wallet: ExpressWallet

    public init(fiatCurrency: OnrampFiatCurrency, country: OnrampCountry, wallet: ExpressWallet) {
        self.fiatCurrency = fiatCurrency
        self.country = country
        self.wallet = wallet
    }
}

struct OnrampPair: Hashable {
    let fiatCurrencyCode: String?
    let currency: ExpressCurrency
    let providers: [OnrampProvider]
}
