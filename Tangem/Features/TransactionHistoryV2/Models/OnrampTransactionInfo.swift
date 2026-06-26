//
//  OnrampTransactionInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampTransactionInfo {
    let onrampTransaction: OnrampTransaction

    /// - Note: Nullable since can be fetched asynchronously.
    /// - Note: Can't use `OnrampProvider` instead since it includes heavy `OnrampProviderManager` for no reason.
    let provider: ExpressProvider?

    /// - Note: Nullable since can be fetched asynchronously.
    let fiatCurrency: OnrampFiatCurrency?
}
