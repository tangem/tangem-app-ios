//
//  OnrampUnknownStatusRecord.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampUnknownStatusRecord: Codable, Equatable {
    let userWalletId: String
    let payoutAddress: String
    let toContractAddress: String
    let toNetwork: String
    let since: Date
    let expiresAt: Date
    let provider: ExpressPendingTransactionRecord.Provider
    let paymentMethod: ExpressPendingTransactionRecord.PaymentMethod?
}

extension OnrampUnknownStatusRecord: Identifiable {
    var id: String {
        // ASCII Unit Separator (U+001F): control character that cannot appear in addresses, ids, or network names,
        // so it can't collide with field contents the way "-" or "_" could.
        [
            userWalletId,
            payoutAddress,
            toNetwork.lowercased(),
            toContractAddress.lowercased(),
            provider.id,
            paymentMethod?.id ?? "",
        ].joined(separator: "\u{1F}")
    }
}
