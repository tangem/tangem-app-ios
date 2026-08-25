//
//  GachaAccountView+Summary.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GachaAccountView {
    struct Summary {
        let fiatBalanceText, cryptoBalanceText, collectionCountText: String

        static let unavailable = Summary(
            fiatBalanceText: BalanceFormatter.defaultEmptyBalanceString,
            cryptoBalanceText: BalanceFormatter.defaultEmptyBalanceString,
            collectionCountText: BalanceFormatter.defaultEmptyBalanceString
        )
    }
}
