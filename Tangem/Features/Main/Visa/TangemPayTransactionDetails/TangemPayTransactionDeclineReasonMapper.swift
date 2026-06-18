//
//  TangemPayTransactionDeclineReasonMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum TangemPayTransactionDeclineReasonMapper {
    static func declinedText(for rawReason: String?) -> String {
        guard let rawReason else {
            return Localization.tangemPayTransactionDeclinedNotificationText
        }

        return Localization.tangemPayHistoryItemSpendMcDeclinedReason(localizedReason(for: rawReason))
    }

    private static func localizedReason(for rawReason: String) -> String {
        switch rawReason {
        case "account credit limit exceeded":
            return Localization.tangempayDeclinedReason1
        case "automatic fuel dispenser velocity limit reached, more than 2 transactions were attempted within a 3-day period":
            return Localization.tangempayDeclinedReason2
        case "block transaction from high-risk merchant category codes":
            return Localization.tangempayDeclinedReason3
        case "block transaction from restricted countries [v3-correlation]":
            return Localization.tangempayDeclinedReason4
        case "block transaction from specified high-risk e-commerce merchants",
             "block transactions from specified high-risk e-commerce merchants",
             "block transactions from specified high ecom merchant":
            return Localization.tangempayDeclinedReason5
        case "block transactions over 150 usd at automated fuel dispensers":
            return Localization.tangempayDeclinedReason6
        case "blocked mcc":
            return Localization.tangempayDeclinedReason7
        case "blocked merchant":
            return Localization.tangempayDeclinedReason8
        case "card locked":
            return Localization.tangempayDeclinedReason9
        case "card spending limit exceeded":
            return Localization.tangempayDeclinedReason10
        case "cvv2 match fail":
            return Localization.tangempayDeclinedReason11
        case "expiry in de14 not matching database stored expiry for this card":
            return Localization.tangempayDeclinedReason12
        case "incorrect pin":
            return Localization.tangempayDeclinedReason13
        case "transaction not permitted to cardholder":
            return Localization.tangempayDeclinedReason14
        case "transaction velocity limit reached, more than 25 transactions were attempted within a 2-day period":
            return Localization.tangempayDeclinedReason15
        case "triggers if there is a suspected bin attack from a merchant":
            return Localization.tangempayDeclinedReason16
        case "webhook declined":
            return Localization.tangempayDeclinedReason17
        default:
            return rawReason
        }
    }
}
