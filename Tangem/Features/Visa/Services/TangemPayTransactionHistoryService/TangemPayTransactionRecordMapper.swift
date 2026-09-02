//
//  TangemPayTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemPay

struct TangemPayTransactionRecordMapper {
    private let transaction: TangemPayTransactionRecord
    private let displayRecord: TangemPayDisplayRecord

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(transaction: TangemPayTransactionRecord) {
        self.transaction = transaction
        displayRecord = transaction.record.displayRecord
    }

    func time() -> String {
        transaction.transactionDate.formatted(date: .omitted, time: .shortened)
    }

    func isOutgoing() -> Bool {
        switch displayRecord {
        case .merchant, .payment, .fee:
            return true
        case .collateral(let collateral):
            return collateral.amount < 0
        }
    }

    func type() -> TransactionViewModel.TransactionType {
        let type: TransactionViewModel.TangemPayTransactionType = switch displayRecord {
        case .merchant(let merchant):
            .spend(
                name: name(),
                icon: merchant.enrichedMerchantIcon,
                isDeclined: merchant.isDeclined,
                isNegativeAmount: merchant.amount < .zero
            )
        case .collateral:
            .transfer(name: name())
        case .payment:
            .transfer(name: name())
        case .fee:
            .fee(name: name())
        }

        return .tangemPay(type)
    }

    /// `TransactionViewModel.Status` will use in `TransactionListView`
    func status() -> TransactionViewModel.Status {
        switch displayRecord {
        case .merchant, .collateral, .payment, .fee:
            return .confirmed
        }
    }

    /// The record amount with correct `sign` (minus or plus)
    func amount() -> String {
        switch displayRecord {
        case .merchant(let merchant) where merchant.amount == 0:
            return format(amount: merchant.amount, currencyCode: merchant.currency)
        case .merchant(let merchant):
            let prefix: String = merchant.amount < 0 ? .plusSign : .empty
            return format(
                amount: -(merchant.isDeclined ? merchant.authorizedAmount : merchant.amount),
                currencyCode: merchant.currency,
                prefix: prefix
            )
        case .collateral(let collateral):
            // In the `collateral.currency` we have `USDC` crypto token
            // But we have to show user just simple `$` currency
            let prefix: String = collateral.amount > 0 ? .plusSign : .empty
            return format(amount: collateral.amount, currencyCode: AppConstants.usdCurrencyCode, prefix: prefix)
        case .payment(let payment):
            return format(amount: -payment.amount, currencyCode: payment.currency)
        case .fee(let fee):
            return format(amount: -fee.amount, currencyCode: fee.currency)
        }
    }

    func cashback() -> TransactionViewModel.Cashback? {
        guard case .merchant(let merchant) = displayRecord,
              let status = merchant.cashbackStatus,
              let amount = merchant.cashback,
              amount != 0,
              let style = TransactionViewModel.Cashback.Style(status: status, amount: amount)
        else {
            return nil
        }

        return TransactionViewModel.Cashback(
            formattedAmount: format(
                amount: amount,
                currencyCode: merchant.cashbackCurrencyCode ?? AppConstants.usdCurrencyCode,
                prefix: amount > 0 ? .plusSign : .empty
            ),
            style: style
        )
    }

    func cardId() -> String? {
        switch displayRecord {
        case .merchant(let merchant):
            return merchant.cardId
        case .collateral, .payment, .fee:
            return nil
        }
    }

    func name() -> String {
        switch displayRecord {
        case .merchant(let merchant):
            return merchant.enrichedMerchantName ?? merchant.merchantName ?? Localization.tangempayCardDetailsTitle
        case .collateral(let collateral):
            if collateral.amount > 0 {
                return Localization.tangemPayDeposit
            } else {
                return Localization.tangemPayWithdrawal
            }
        case .payment:
            return Localization.tangemPayWithdrawal
        case .fee:
            return Localization.tangemPayFeeTitle
        }
    }

    func categoryName(detailed: Bool) -> String {
        switch displayRecord {
        case .merchant(let merchant):
            if detailed, let category = merchant.merchantCategory, let mcc = merchant.merchantCategoryCode {
                return .merchantCategory(category: category, mcc: mcc)
            }

            return merchant.merchantCategory?.nilIfEmpty
                ?? merchant.enrichedMerchantCategory?.nilIfEmpty
                ?? Localization.tangemPayOther
        case .collateral:
            return Localization.commonTransfer
        case .payment:
            return Localization.commonTransfer
        case .fee(let fee):
            return fee.description ?? Localization.tangemPayFeeSubtitle
        }
    }

    private func format(amount: Decimal, currencyCode: String, prefix: String = "") -> String {
        amountFormatter.currencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: currencyCode.uppercased())
        let formatted = amountFormatter.format(number: amount)
        return "\(prefix)\(formatted)"
    }
}

private extension TransactionViewModel.Cashback.Style {
    init?(status: TangemPayCashbackStatus, amount: Decimal) {
        switch status {
        case .estimated:
            self = amount < 0 ? .refunded : .estimated
        case .confirmed:
            self = amount < 0 ? .refunded : .confirmed
        case .excluded, .awaitingCalculation, .undefined:
            return nil
        }
    }
}

private extension String {
    static func merchantCategory(category: String, mcc: String) -> String {
        return category + " " + AppConstants.dotSign + " " + Localization.tangemPayHistoryItemSpendMcc(mcc)
    }
}
