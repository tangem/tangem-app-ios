//
//  CollectiblesAccountView+Summary.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

extension CollectiblesAccountView {
    struct Summary {
        let fiatBalance: LoadableBalanceView.State
        let fiatBalancePlainText: String
        let cryptoBalanceText: String
        let collectionCountText: String
        let isWithdrawalAvailable: Bool
        let isBalanceUpdating: Bool

        static let placeholder = Summary(
            fiatBalance: .loading(),
            fiatBalancePlainText: BalanceFormatter.defaultEmptyBalanceString,
            cryptoBalanceText: BalanceFormatter.defaultEmptyBalanceString,
            collectionCountText: BalanceFormatter.defaultEmptyBalanceString,
            isWithdrawalAvailable: false,
            isBalanceUpdating: true
        )
    }
}
