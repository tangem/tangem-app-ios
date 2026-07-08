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
    }

    func time() -> String {
        transaction.transactionDate.formatted(date: .omitted, time: .shortened)
    }

    func isOutgoing() -> Bool {
        switch transaction.record {
        case .spend, .payment, .fee:
            return true
        case .collateral(let collateral):
            return collateral.amount < 0
        }
    }

    func type() -> TransactionViewModel.TransactionType {
        let type: TransactionViewModel.TangemPayTransactionType = switch transaction.record {
        case .spend(let spend):
            .spend(
                name: name(),
                icon: spend.enrichedMerchantIcon,
                isDeclined: spend.isDeclined,
                isNegativeAmount: spend.amount < .zero
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
        switch transaction.record {
        case .spend, .collateral, .payment, .fee:
            return .confirmed
        }
    }

    /// The record amount with correct `sign` (minus or plus)
    func amount() -> String {
        switch transaction.record {
        case .spend(let spend) where spend.amount == 0:
            return format(amount: spend.amount, currencyCode: spend.currency)
        case .spend(let spend):
            let prefix: String = spend.amount < 0 ? .plusSign : .empty
            return format(
                amount: -(spend.isDeclined ? spend.authorizedAmount : spend.amount),
                currencyCode: spend.currency,
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

    func cardId() -> String? {
        switch transaction.record {
        case .spend(let spend):
            return spend.cardId
        case .collateral, .payment, .fee:
            return nil
        }
    }

    func name() -> String {
        switch transaction.record {
        case .spend(let spend):
            return spend.enrichedMerchantName ?? spend.merchantName ?? Localization.tangempayCardDetailsTitle
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
        switch transaction.record {
        case .spend(let spend):
            if detailed, let category = spend.merchantCategory, let mcc = spend.merchantCategoryCode {
                return .merchantCategory(category: category, mcc: mcc)
            }

            return spend.merchantCategory?.nilIfEmpty
                ?? spend.enrichedMerchantCategory?.nilIfEmpty
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

private extension String {
    static func merchantCategory(category: String, mcc: String) -> String {
        return category + " " + AppConstants.dotSign + " " + Localization.tangemPayHistoryItemSpendMcc(mcc)
    }
}
