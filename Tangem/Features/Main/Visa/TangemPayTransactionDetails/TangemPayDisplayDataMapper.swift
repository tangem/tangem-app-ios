//
//  TangemPayDisplayDataMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPay

struct TangemPayDisplayDataMapper {
    private let dateFormatter = DateFormatter(dateFormat: "dd MMM")
    private let amountFormatter: TangemPayFiatAmountFormatter

    init(amountFormatter: TangemPayFiatAmountFormatter = .init()) {
        self.amountFormatter = amountFormatter
    }

    func map(spend input: TangemPaySpendDisplayInput) -> TangemPayTransactionDetailsViewModel.DisplayData {
        let name = input.enrichedMerchantName
            ?? input.merchantName
            ?? Localization.tangempayCardDetailsTitle

        let isDeclined = input.status == .declined
        let isReversed = input.status == .reversed

        let type: TransactionViewModel.TransactionType = .tangemPay(
            .spend(
                name: name,
                icon: input.enrichedMerchantIcon,
                isDeclined: isDeclined,
                isNegativeAmount: input.amount < .zero
            )
        )

        let state: TangemPayTransactionDetailsStateView.TransactionState = switch input.status {
        case .completed: .completed
        case .declined: .declined
        case .pending: .pending
        case .reversed: .reversed
        }

        let formattedAmount = input.formattedAmount(using: amountFormatter)
        let formattedLocalAmount = input.formattedLocalAmount(using: amountFormatter)

        let categoryName: String = {
            if let category = input.merchantCategory, let mcc = input.merchantCategoryCode {
                return "\(category) \(AppConstants.dotSign) \(Localization.tangemPayHistoryItemSpendMcc(mcc))"
            }
            return input.merchantCategory?.nilIfEmpty
                ?? input.enrichedMerchantCategory?.nilIfEmpty
                ?? Localization.tangemPayOther
        }()

        let additionalInfo: TangemPayTransactionDetailsView.AdditionalInfo? = if isDeclined {
            .declined(reason: input.declinedReason)
        } else if isReversed {
            .reversed
        } else {
            nil
        }

        return .init(
            date: dateFormatter.string(from: input.transactionDate),
            time: input.transactionDate.formatted(date: .omitted, time: .shortened),
            type: type,
            status: .confirmed,
            isOutgoing: true,
            name: name,
            categoryName: categoryName,
            amount: formattedAmount,
            localAmount: formattedLocalAmount,
            state: state,
            additionalInfo: additionalInfo,
            mainButtonAction: .dispute
        )
    }

    func map(collateral input: TangemPayCollateralDisplayInput) -> TangemPayTransactionDetailsViewModel.DisplayData {
        let name = input.isOutgoing ? Localization.tangemPayWithdrawal : Localization.tangemPayDeposit
        let type: TransactionViewModel.TransactionType = .tangemPay(.transfer(name: name))
        let formattedAmount = amountFormatter.formatSigned(input.amount, currencyCode: AppConstants.usdCurrencyCode)

        return .init(
            date: dateFormatter.string(from: input.postedAt),
            time: input.postedAt.formatted(date: .omitted, time: .shortened),
            type: type,
            status: .confirmed,
            isOutgoing: input.isOutgoing,
            name: name,
            categoryName: Localization.commonTransfer,
            amount: formattedAmount,
            localAmount: nil,
            state: nil,
            additionalInfo: nil,
            mainButtonAction: .info
        )
    }

    func map(payment input: TangemPayPaymentDisplayInput) -> TangemPayTransactionDetailsViewModel.DisplayData {
        let name = Localization.tangemPayWithdrawal
        let type: TransactionViewModel.TransactionType = .tangemPay(.transfer(name: name))
        let formattedAmount = amountFormatter.format(-input.amount, currencyCode: input.currency)

        return .init(
            date: dateFormatter.string(from: input.postedAt),
            time: input.postedAt.formatted(date: .omitted, time: .shortened),
            type: type,
            status: .confirmed,
            isOutgoing: true,
            name: name,
            categoryName: Localization.commonTransfer,
            amount: formattedAmount,
            localAmount: nil,
            state: nil,
            additionalInfo: nil,
            mainButtonAction: .info
        )
    }

    func map(fee input: TangemPayFeeDisplayInput) -> TangemPayTransactionDetailsViewModel.DisplayData {
        let name = Localization.tangemPayFeeTitle
        let type: TransactionViewModel.TransactionType = .tangemPay(.fee(name: name))
        let formattedAmount = amountFormatter.format(-input.amount, currencyCode: input.currency)

        return .init(
            date: dateFormatter.string(from: input.postedAt),
            time: input.postedAt.formatted(date: .omitted, time: .shortened),
            type: type,
            status: .confirmed,
            isOutgoing: true,
            name: name,
            categoryName: input.description ?? Localization.tangemPayFeeSubtitle,
            amount: formattedAmount,
            localAmount: nil,
            state: nil,
            additionalInfo: .fee,
            mainButtonAction: .dispute
        )
    }
}

// MARK: - Inputs

struct TangemPaySpendDisplayInput {
    let transactionDate: Date
    let merchantName: String?
    let enrichedMerchantName: String?
    let enrichedMerchantIcon: URL?
    let amount: Decimal
    let authorizedAmount: Decimal
    let currency: String
    let localAmount: Decimal?
    let localCurrency: String?
    let merchantCategory: String?
    let enrichedMerchantCategory: String?
    let merchantCategoryCode: String?
    let status: Status
    let declinedReason: String?

    enum Status: Equatable {
        case completed
        case declined
        case pending
        case reversed
    }
}

extension TangemPaySpendDisplayInput {
    /// A charge is shown as money leaving the card (`-$12.30`); a refund (negative `amount`) as money coming
    /// back (`+$12.30`). A declined charge shows the amount the merchant tried to authorize.
    func formattedAmount(using formatter: TangemPayFiatAmountFormatter) -> String {
        guard amount != 0 else {
            return formatter.format(.zero, currencyCode: currency)
        }

        let charged = status == .declined ? authorizedAmount : amount
        return formatter.formatSigned(-charged, currencyCode: currency)
    }

    /// The amount in the merchant's currency, signed like `formattedAmount(using:)`.
    /// `nil` when the merchant charged in the card currency or the local amount is unknown.
    func formattedLocalAmount(using formatter: TangemPayFiatAmountFormatter) -> String? {
        guard let localAmount, let localCurrency, currency != localCurrency else {
            return nil
        }

        return formatter.formatSigned(-localAmount, currencyCode: localCurrency)
    }
}

struct TangemPayCollateralDisplayInput {
    let postedAt: Date
    let amount: Decimal
    let isOutgoing: Bool
}

struct TangemPayPaymentDisplayInput {
    let postedAt: Date
    let amount: Decimal
    let currency: String
}

struct TangemPayFeeDisplayInput {
    let postedAt: Date
    let amount: Decimal
    let currency: String
    let description: String?
}

// MARK: - History projections

extension TangemPayTransactionRecord {
    func displayData(using mapper: TangemPayDisplayDataMapper) -> TangemPayTransactionDetailsViewModel.DisplayData {
        switch record.displayRecord {
        case .merchant(let merchant):
            return mapper.map(spend: merchant.displayInput)
        case .collateral(let collateral):
            return mapper.map(collateral: collateral.displayInput)
        case .payment(let payment):
            return mapper.map(payment: payment.displayInput)
        case .fee(let fee):
            return mapper.map(fee: fee.displayInput)
        }
    }
}

extension TangemPayMerchantRecord {
    var displayInput: TangemPaySpendDisplayInput {
        .init(
            transactionDate: transactionDate,
            merchantName: merchantName,
            enrichedMerchantName: enrichedMerchantName,
            enrichedMerchantIcon: enrichedMerchantIcon,
            amount: amount,
            authorizedAmount: authorizedAmount,
            currency: currency,
            localAmount: localAmount,
            localCurrency: localCurrency,
            merchantCategory: merchantCategory,
            enrichedMerchantCategory: enrichedMerchantCategory,
            merchantCategoryCode: merchantCategoryCode,
            status: .init(status),
            declinedReason: declinedReason
        )
    }
}

extension TangemPayTransactionHistoryResponse.Collateral {
    var displayInput: TangemPayCollateralDisplayInput {
        .init(postedAt: postedAt, amount: amount, isOutgoing: amount < 0)
    }
}

extension TangemPayTransactionHistoryResponse.Payment {
    var displayInput: TangemPayPaymentDisplayInput {
        .init(postedAt: postedAt, amount: amount, currency: currency)
    }
}

extension TangemPayTransactionHistoryResponse.Fee {
    var displayInput: TangemPayFeeDisplayInput {
        .init(postedAt: postedAt, amount: amount, currency: currency, description: description)
    }
}

private extension TangemPaySpendDisplayInput.Status {
    init(_ status: TangemPayTransactionHistoryResponse.PaymentStatus) {
        self = switch status {
        case .completed: .completed
        case .declined: .declined
        case .pending, .undefined: .pending
        case .reversed: .reversed
        }
    }
}

// MARK: - Push projections

extension TangemPayPushPayload {
    func displayData(using mapper: TangemPayDisplayDataMapper) -> TangemPayTransactionDetailsViewModel.DisplayData? {
        switch body {
        case .transactionSpend(let spend),
             .transactionSpendRefund(let spend),
             .declinedTopUp(let spend),
             .declinedReason1(let spend),
             .declinedReason2(let spend),
             .declinedReason3(let spend),
             .declinedReason4(let spend),
             .declinedReason5(let spend),
             .declinedReason6(let spend),
             .declinedReason7(let spend),
             .declinedReason8(let spend),
             .declinedReason9(let spend),
             .declinedReason10(let spend),
             .declinedReason11(let spend),
             .declinedReason12(let spend),
             .declinedReason13(let spend),
             .declinedReason14(let spend),
             .declinedReason15(let spend),
             .declinedReason16(let spend),
             .declinedReason17(let spend):
            return mapper.map(spend: spend.displayInput)
        case .collateralWithdraw(let collateral):
            return mapper.map(collateral: collateral.displayInput(isOutgoing: true))
        case .collateralDeposit(let collateral):
            return mapper.map(collateral: collateral.displayInput(isOutgoing: false))
        case .cardReady, .thresholdTopUp:
            return nil
        }
    }
}

extension TangemPayPushPayload.Spend {
    var displayInput: TangemPaySpendDisplayInput {
        .init(
            transactionDate: authorizedAt,
            merchantName: merchantName,
            enrichedMerchantName: enrichedMerchantName,
            enrichedMerchantIcon: enrichedMerchantIcon,
            amount: amount,
            authorizedAmount: amount,
            currency: currency,
            localAmount: localAmount,
            localCurrency: localCurrency,
            merchantCategory: merchantCategory,
            enrichedMerchantCategory: enrichedMerchantCategory,
            merchantCategoryCode: merchantCategoryCode,
            status: .init(status),
            declinedReason: declinedReason
        )
    }
}

extension TangemPayPushPayload.Collateral {
    func displayInput(isOutgoing: Bool) -> TangemPayCollateralDisplayInput {
        .init(postedAt: postedAt, amount: isOutgoing ? -amount : amount, isOutgoing: isOutgoing)
    }
}

private extension TangemPaySpendDisplayInput.Status {
    init(_ status: TangemPayPushPayload.Spend.Status) {
        self = switch status {
        case .approved, .completed: .completed
        case .declined: .declined
        case .pending: .pending
        case .reversed: .reversed
        }
    }
}
