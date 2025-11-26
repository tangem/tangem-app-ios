//
//  TangemPayAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemVisa

struct TangemPayAccountViewModel {
    enum State {
        case normal(card: VisaCustomerInfoResponse.Card, balance: TangemPayBalance)
        case syncNeeded
        case unavailable

        var subtitle: String {
            switch self {
            case .normal(let card, _):
                "*" + card.cardNumberEnd
            case .syncNeeded:
                Localization.tangempayPaymentAccountSyncNeeded
            case .unavailable:
                "—"
            }
        }

        var balanceText: String? {
            switch self {
            case .normal(_, let balance):
                "$ " + balance.fiat.availableBalance.description
            case .syncNeeded, .unavailable:
                nil
            }
        }

        var isNormal: Bool {
            switch self {
            case .normal:
                true
            case .syncNeeded, .unavailable:
                false
            }
        }
    }

    let state: State
    let tapAction: () -> Void
}
