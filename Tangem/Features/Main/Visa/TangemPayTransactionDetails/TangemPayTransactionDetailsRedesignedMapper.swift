//
//  TangemPayTransactionDetailsRedesignedMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay

struct TangemPayTransactionDetailsRedesignedMapper {
    private let dateFormatter = DateFormatter(dateFormat: "MMM d yyyy")
    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func map(spend input: TangemPaySpendDisplayInput, cardName: String?) -> TangemPayTransactionDetailsDisplayModel {
        let merchantName = input.enrichedMerchantName
            ?? input.merchantName
            ?? Localization.tangempayCardDetailsTitle

        let isDeclined = input.status == .declined

        let amount = if input.amount == 0 {
            format(amount: .zero, currencyCode: input.currency)
        } else {
            formatNegated(
                value: isDeclined ? input.authorizedAmount : input.amount,
                currency: input.currency,
                prefixFor: input.amount
            )
        }

        let foreignAmount: String? = {
            guard let localAmount = input.localAmount,
                  let localCurrency = input.localCurrency,
                  input.currency != localCurrency
            else {
                return nil
            }
            return formatNegated(value: localAmount, currency: localCurrency, prefixFor: input.amount)
        }()

        let amountSubtitle = foreignAmount.map { "\($0) \(AppConstants.dotSign) \(merchantName)" } ?? merchantName

        let category = input.merchantCategory?.nilIfEmpty
            ?? input.enrichedMerchantCategory?.nilIfEmpty
            ?? Localization.tangemPayOther

        var rows: [TangemPayTransactionDetailsDisplayModel.Row] = []
        if let cardName {
            rows.append(.init(title: Localization.tangempayDigitalCard, value: cardName))
        }
        rows.append(.init(title: Localization.tangemPayTransactionDetailsCategory, value: category))
        if let mcc = input.merchantCategoryCode?.nilIfEmpty {
            rows.append(.init(title: Localization.tangemPayTransactionDetailsMcc, value: mcc))
        }

        return .init(
            headerTitle: Localization.tangemPayPurchase,
            headerSubtitle: formatDateTime(input.transactionDate),
            icon: .merchantLogo(input.enrichedMerchantIcon),
            amount: amount,
            amountSubtitle: amountSubtitle,
            status: status(for: input.status, declinedReason: input.declinedReason),
            rows: rows,
            mainButtonAction: .dispute
        )
    }

    func map(collateral input: TangemPayCollateralDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        let prefix = input.amount > 0 ? "+" : ""
        return .init(
            headerTitle: input.isOutgoing ? Localization.tangemPayWithdrawal : Localization.tangemPayDeposit,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: input.isOutgoing ? .withdrawal : .deposit,
            amount: format(amount: input.amount, currencyCode: AppConstants.usdCurrencyCode, prefix: prefix),
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        )
    }

    func map(payment input: TangemPayPaymentDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        .init(
            headerTitle: Localization.tangemPayWithdrawal,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: .withdrawal,
            amount: format(amount: -input.amount, currencyCode: input.currency),
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        )
    }

    func map(fee input: TangemPayFeeDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        .init(
            headerTitle: Localization.tangemPayFeeTitle,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: .fee,
            amount: format(amount: -input.amount, currencyCode: input.currency),
            amountSubtitle: input.description?.nilIfEmpty,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.tangemPayFeeSubtitle)],
            mainButtonAction: .dispute
        )
    }

    private func status(
        for status: TangemPaySpendDisplayInput.Status,
        declinedReason: String?
    ) -> TangemPayTransactionStatusView.Model {
        switch status {
        case .pending:
            .init(style: .inProgress, title: Localization.commonInProgress, reason: nil)
        case .completed:
            .init(style: .completed, title: Localization.tangemPayStatusCompleted, reason: nil)
        case .declined:
            .init(
                style: .rejected,
                title: Localization.tangemPayStatusDeclined,
                reason: TangemPayTransactionDeclineReasonMapper.declinedText(for: declinedReason)
            )
        case .reversed:
            .init(style: .reversed, title: Localization.tangemPayStatusReversed, reason: nil)
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let day = dateFormatter.string(from: date)
        let time = date.formatted(date: .omitted, time: .shortened)
        return "\(day), \(time)"
    }

    private func format(amount: Decimal, currencyCode: String, prefix: String = "") -> String {
        amountFormatter.currencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: currencyCode.uppercased())
        let formatted = amountFormatter.format(number: amount)
        return "\(prefix)\(formatted)"
    }

    private func formatNegated(value: Decimal, currency: String, prefixFor amount: Decimal) -> String {
        let prefix = amount < 0 ? "+" : ""
        return format(amount: -value, currencyCode: currency, prefix: prefix)
    }
}

// MARK: - History projection

extension TangemPayTransactionRecord {
    func redesignedDisplayModel(
        using mapper: TangemPayTransactionDetailsRedesignedMapper,
        cardName: String?
    ) -> TangemPayTransactionDetailsDisplayModel {
        switch record {
        case .spend(let spend): mapper.map(spend: spend.displayInput, cardName: cardName)
        case .collateral(let collateral): mapper.map(collateral: collateral.displayInput)
        case .payment(let payment): mapper.map(payment: payment.displayInput)
        case .fee(let fee): mapper.map(fee: fee.displayInput)
        }
    }
}

// MARK: - Push projection

extension TangemPayPushPayload {
    func redesignedDisplayModel(
        using mapper: TangemPayTransactionDetailsRedesignedMapper
    ) -> TangemPayTransactionDetailsDisplayModel? {
        switch body {
        case .transactionSpend(let spend), .declinedTopUp(let spend):
            mapper.map(spend: spend.displayInput, cardName: nil)
        case .collateralWithdraw(let collateral):
            mapper.map(collateral: collateral.displayInput(isOutgoing: true))
        case .collateralDeposit(let collateral):
            mapper.map(collateral: collateral.displayInput(isOutgoing: false))
        case .cardReady:
            nil
        }
    }
}
