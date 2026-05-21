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
    let fromAddress: String
    let toContractAddress: String
    let toNetwork: String
    let since: Date
    let expiresAt: Date
    let provider: ExpressPendingTransactionRecord.Provider
    let paymentMethod: ExpressPendingTransactionRecord.PaymentMethod?
}

extension OnrampUnknownStatusRecord: Identifiable {
    var id: String {
        [userWalletId, fromAddress, toNetwork.lowercased(), toContractAddress.lowercased(), provider.id]
            .joined(separator: "\u{1F}")
    }
}
