//
//  OnrampTransactionInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct OnrampTransactionInfo: Hashable {
    let onrampTransaction: OnrampTransaction

    /// - Note: Nullable since can be fetched asynchronously.
    /// - Note: Can't use `OnrampProvider` instead since it includes heavy `OnrampProviderManager` for no reason.
    let provider: ExpressProvider?

    /// - Note: Nullable since can be fetched asynchronously.
    let fiatCurrency: OnrampFiatCurrency?

    /// Use this dictionary to resolve an `OnrampTransaction`'s `ExpressCurrency` to a `TokenItem` for use in the UI layer.
    /// - Note: Cache misses are expected since this dictionary can be populated asynchronously.
    let cryptoCurrencies: [ExpressCurrency: TokenItem]
}
