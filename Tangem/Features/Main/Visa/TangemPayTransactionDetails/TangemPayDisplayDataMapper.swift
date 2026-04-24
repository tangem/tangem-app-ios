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
    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesSignificantDigits = true
        return formatter
    }()

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

        let formattedAmount = if input.amount == 0 {
            format(amount: .zero, currencyCode: input.currency)
        } else {
            formatNegated(
                value: isDeclined ? input.authorizedAmount : input.amount,
                currency: input.currency,
                prefixFor: input.amount
            )
        }

        let formattedLocalAmount: String? = {
            guard let localAmount = input.localAmount,
                  let localCurrency = input.localCurrency,
                  input.currency != localCurrency
            else {
                return nil
            }
            return formatNegated(value: localAmount, currency: localCurrency, prefixFor: input.amount)
        }()

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
            date: dateFormatter.string(from: input.authorizedAt),
            time: input.authorizedAt.formatted(date: .omitted, time: .shortened),
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

        let prefix = input.amount > 0 ? "+" : ""
        let formattedAmount = format(amount: input.amount, currencyCode: AppConstants.usdCurrencyCode, prefix: prefix)

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
        let formattedAmount = format(amount: -input.amount, currencyCode: input.currency)

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
        let formattedAmount = format(amount: -input.amount, currencyCode: input.currency)

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

// MARK: - Inputs

struct TangemPaySpendDisplayInput {
    let authorizedAt: Date
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
        switch record {
        case .spend(let spend):
            return mapper.map(spend: spend.displayInput)
        case .collateral(let collateral):
            return mapper.map(collateral: collateral.displayInput)
        case .payment(let payment):
            return mapper.map(payment: payment.displayInput)
        case .fee(let fee):
            return mapper.map(fee: fee.displayInput)
        }
    }
}

private extension TangemPayTransactionHistoryResponse.Spend {
    var displayInput: TangemPaySpendDisplayInput {
        .init(
            authorizedAt: authorizedAt,
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

private extension TangemPayTransactionHistoryResponse.Collateral {
    var displayInput: TangemPayCollateralDisplayInput {
        .init(postedAt: postedAt, amount: amount, isOutgoing: amount < 0)
    }
}

private extension TangemPayTransactionHistoryResponse.Payment {
    var displayInput: TangemPayPaymentDisplayInput {
        .init(postedAt: postedAt, amount: amount, currency: currency)
    }
}

private extension TangemPayTransactionHistoryResponse.Fee {
    var displayInput: TangemPayFeeDisplayInput {
        .init(postedAt: postedAt, amount: amount, currency: currency, description: description)
    }
}

private extension TangemPaySpendDisplayInput.Status {
    init(_ status: TangemPayTransactionHistoryResponse.PaymentStatus) {
        self = switch status {
        case .completed: .completed
        case .declined: .declined
        case .pending: .pending
        case .reversed: .reversed
        }
    }
}

// MARK: - Push projections

extension TangemPayPushPayload {
    func displayData(using mapper: TangemPayDisplayDataMapper) -> TangemPayTransactionDetailsViewModel.DisplayData? {
        switch body {
        case .transactionSpend(let spend), .declinedTopUp(let spend):
            return mapper.map(spend: spend.displayInput)
        case .collateralWithdraw(let collateral):
            return mapper.map(collateral: collateral.displayInput(isOutgoing: true))
        case .collateralDeposit(let collateral):
            return mapper.map(collateral: collateral.displayInput(isOutgoing: false))
        case .cardReady:
            return nil
        }
    }
}

private extension TangemPayPushPayload.Spend {
    var displayInput: TangemPaySpendDisplayInput {
        .init(
            authorizedAt: authorizedAt,
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

private extension TangemPayPushPayload.Collateral {
    func displayInput(isOutgoing: Bool) -> TangemPayCollateralDisplayInput {
        .init(postedAt: postedAt, amount: amount, isOutgoing: isOutgoing)
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
