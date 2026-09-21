//
//  TokenSelectorViewModel+Deeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenSelectorViewModel {
    /// The selector a `tangem://sell` deeplink opens, wherever it is shown from.
    static func deeplinkSell() -> TokenSelectorViewModel {
        .common(walletsProvider: .cryptoJointAccounts(), availabilityProvider: .sell())
    }
}
