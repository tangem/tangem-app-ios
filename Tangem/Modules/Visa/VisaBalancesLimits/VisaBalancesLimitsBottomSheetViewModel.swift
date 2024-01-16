//
//  VisaBalancesLimitsBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class VisaBalancesLimitsBottomSheetViewModel: ObservableObject, Identifiable {
    @Published var alert: AlertBinder? = nil

    // MARK: Balances related

    // [REDACTED_TODO_COMMENT]
    var totalAmount: String { "492.45" }
    var amlVerifiedAmount: String { "392.45" }
    var availableAmount: String { "356.45" }
    var blockedAmount: String { "36.00" }
    var debtAmount: String { "0.00" }
    var pendingRefundAmount: String { "20.99" }

    // MARK: Limits related

    // [REDACTED_TODO_COMMENT]
    // one time purchase
    var availabilityDescription: String { "Available by Nov, 11" }
    var inStoreOtpAmount: String { "563.00" }
    var otherNoOtpAmount: String { "100.00" }
    var singleTransactionAmount: String { "100.00" }

    func openBalancesInfo() {
        alert = AlertBinder(title: "", message: "Available balance is actual funds available, considering pending transactions, blocked amounts, and debit balance to prevent overdrafts.")
    }

    func openLimitsInfo() {
        alert = AlertBinder(title: "", message: "Limits are needed to control costs, improve security, manage risk. You can spend 1 000 USDT during the week for card payments in shops and 100 USDT for other transactions, e. g. subscriptions or debts.")
    }
}
