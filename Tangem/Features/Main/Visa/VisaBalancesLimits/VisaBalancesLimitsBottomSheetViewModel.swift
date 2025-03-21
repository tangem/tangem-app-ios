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

    // MARK: Limits related

    // OTP - One time password
    let availabilityDescription: String
    let remainingOTPAmount: String
    // No OTP - amount that could be spent without use of One Time Password
    let remainingNoOtpAmount: String
    let singleTransactionAmount: String

    private let formatter: BalanceFormatter = .init()
    private let balanceFormattingOptions: BalanceFormattingOptions = .init(minFractionDigits: 2, maxFractionDigits: 2, formatEpsilonAsLowestRepresentableValue: false, roundingType: .default(roundingMode: .down, scale: 2))

    init(balances: AppVisaBalances, limit: AppVisaLimit, currencySymbol: String) {
        totalAmount = formatter.formatCryptoBalance(balances.totalBalance, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
        amlVerifiedAmount = formatter.formatCryptoBalance(balances.verifiedBalance, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
        availableAmount = formatter.formatCryptoBalance(balances.available, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
        blockedAmount = formatter.formatCryptoBalance(balances.blocked, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
        debtAmount = formatter.formatCryptoBalance(balances.debt, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)

        singleTransactionAmount = formatter.formatCryptoBalance(limit.singleTransaction, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY"
        availabilityDescription = Localization.visaMainAvailableTillDate(dateFormatter.string(from: limit.actualExpirationDate))
        remainingOTPAmount = formatter.formatCryptoBalance(limit.remainingOTPAmount, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
        remainingNoOtpAmount = formatter.formatCryptoBalance(limit.remainingNoOTPAmount, currencyCode: currencySymbol, formattingOptions: balanceFormattingOptions)
    }

    func openBalancesInfo() {
        alert = AlertBinder(title: "", message: Localization.visaMainAvailableBalanceAlertMessage)
    }

    func openLimitsInfo() {
        alert = AlertBinder(
            title: "",
            message: Localization.visaMainLimitsAlertDescriptionMessage(
                remainingOTPAmount,
                remainingNoOtpAmount
            )
        )
    }
}
