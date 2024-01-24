//
//  VisaBalancesLimitsBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

class VisaBalancesLimitsBottomSheetViewModel: ObservableObject, Identifiable {
    @Published var alert: AlertBinder? = nil

    // MARK: Balances related

    let totalAmount: String
    let amlVerifiedAmount: String
    let availableAmount: String
    let blockedAmount: String
    let debtAmount: String
    let pendingRefundAmount: String

    // MARK: Limits related

    // OTP - One time password
    let availabilityDescription: String
    let remainingOTPAmount: String
    // No OTP - amount that could be spent without use of One Time Password
    let remainingNoOtpAmount: String
    let singleTransactionAmount: String

    private let emptyAmount = BalanceFormatter.defaultEmptyBalanceString
    private let formatter: BalanceFormatter = .init()
    private let balanceFormattingOptions: BalanceFormattingOptions = .init(minFractionDigits: 2, maxFractionDigits: 2, roundingType: .default(roundingMode: .down, scale: 2))

    init(balances: AppVisaBalances, limit: AppVisaLimit) {
        let tokenCurrencyCode = VisaUtilities().visaToken.symbol
        totalAmount = formatter.formatCryptoBalance(balances.totalBalance, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        amlVerifiedAmount = formatter.formatCryptoBalance(balances.verifiedBalance, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        availableAmount = formatter.formatCryptoBalance(balances.available, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        blockedAmount = formatter.formatCryptoBalance(balances.blocked, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        debtAmount = formatter.formatCryptoBalance(balances.debt, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        pendingRefundAmount = formatter.formatCryptoBalance(balances.pendingRefund, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)

        singleTransactionAmount = formatter.formatCryptoBalance(limit.singleTransaction, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY"
        availabilityDescription = "Available till \(dateFormatter.string(from: limit.actualExpirationDate))"
        remainingOTPAmount = formatter.formatCryptoBalance(limit.remainingOTPAmount, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
        remainingNoOtpAmount = formatter.formatCryptoBalance(limit.remainingNoOTPAmount, currencyCode: tokenCurrencyCode, formattingOptions: balanceFormattingOptions)
    }

    func openBalancesInfo() {
        alert = AlertBinder(title: "", message: "Available balance is actual funds available, considering pending transactions, blocked amounts, and debit balance to prevent overdrafts.")
    }

    func openLimitsInfo() {
        alert = AlertBinder(title: "", message: "Limits are needed to control costs, improve security, manage risk. You can spend 1 000 USDT during the week for card payments in shops and 100 USDT for other transactions, e. g. subscriptions or debts.")
    }
}
