//
//  TangemPayTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemLocalization
import TangemVisa
import TangemPay
import TangemAssets

struct TangemPayTransactionRecordMapper {
    private let transaction: TangemPayTransactionRecord

    private let dateFormatter = DateFormatter(dateFormat: "dd MMM")
    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesSignificantDigits = true
        return formatter
    }()

    init(transaction: TangemPayTransactionRecord) {
        self.transaction = transaction
    }

    func date() -> String {
        dateFormatter.string(from: transaction.transactionDate)
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

    /// `TangemPayTransactionDetailsStateView.TransactionState` will use in `TangemPayTransactionDetailsView`
    func state() -> TangemPayTransactionDetailsStateView.TransactionState? {
        switch transaction.record {
        case .spend(let spend): switch spend.status {
            case .completed: .completed
            case .declined: .declined
            case .pending: .pending
            case .reversed: .reversed
            }
        case .collateral, .payment, .fee: .none
        }
    }

    func additionalInfo() -> TangemPayTransactionDetailsView.AdditionalInfo? {
        switch transaction.record {
        case .spend(let spend) where spend.isDeclined:
            let text = if let declinedReason = spend.declinedReason {
                Localization.tangemPayHistoryItemSpendMcDeclinedReason(declinedReason)
            } else {
                Localization.tangemPayTransactionDeclinedNotificationText
            }

            return .init(
                text: text,
                textColor: Colors.Text.warning,
                icon: Assets.infoCircle20.image,
                iconColor: Colors.Icon.warning,
                backgroundColor: Colors.Icon.warning.opacity(0.1)
            )

        case .spend(let spend) where spend.isReversed:
            return .init(
                text: Localization.tangemPayTransactionReversedNotificationText,
                textColor: Colors.Text.tertiary,
                icon: Assets.infoCircle20.image,
                iconColor: Colors.Icon.secondary,
                backgroundColor: Colors.Button.disabled
            )

        case .fee:
            return .init(
                text: Localization.tangemPayTransactionFeeNotificationText,
                textColor: Colors.Text.warning,
                icon: Assets.infoCircle20.image,
                iconColor: Colors.Icon.warning,
                backgroundColor: Colors.Icon.warning.opacity(0.1)
            )

        case .spend, .collateral, .payment:
            return .none
        }
    }

    func mainButtonAction() -> TangemPayTransactionDetailsViewModel.MainButtonAction {
        switch transaction.record {
        case .spend, .fee:
            return .dispute
        case .payment, .collateral:
            return .info
        }
    }

    func cryptoTransactionExplorerURL() -> (hash: String, url: URL)? {
        let transactionHash: String? = switch transaction.record {
        case .collateral(let collateral): collateral.transactionHash
        case .payment(let payment): payment.transactionHash
        case .spend, .fee: .none
        }

        guard let transactionHash else {
            return nil
        }

        let provider = ExternalLinkProviderFactory().makeProvider(
            for: TangemPayUtilities.usdcTokenItem.blockchain
        )
        guard let url = provider.url(transaction: transactionHash) else {
            return nil
        }

        return (hash: transactionHash, url: url)
    }

    /// `TransactionViewModel.Status` will use in `TransactionListView`
    func status() -> TransactionViewModel.Status {
        switch transaction.record {
        case .spend(let spend): switch spend.status {
            case .pending: return .inProgress
            case .completed: return .confirmed
            case .declined: return .failed
            case .reversed: return .confirmed
            }
        case .collateral, .payment, .fee:
            return .confirmed
        }
    }

    /// The record amount with correct `sign` (minus or plus)
    func amount() -> String {
        switch transaction.record {
        case .spend(let spend) where spend.amount == 0:
            return format(amount: spend.amount, currencyCode: spend.currency)
        case .spend(let spend):
            let prefix = spend.amount < 0 ? "+" : ""
            return format(amount: -spend.amount, currencyCode: spend.currency, prefix: prefix)
        case .collateral(let collateral):
            // In the `collateral.currency` we have `USDC` crypto token
            // But we have to show user just simple `$` currency
            let prefix = collateral.amount > 0 ? "+" : ""
            return format(amount: collateral.amount, currencyCode: AppConstants.usdCurrencyCode, prefix: prefix)
        case .payment(let payment):
            return format(amount: -payment.amount, currencyCode: payment.currency)
        case .fee(let fee):
            return format(amount: -fee.amount, currencyCode: fee.currency)
        }
    }

    func localAmount() -> String? {
        switch transaction.record {
        case .spend(let spend) where spend.currency != spend.localCurrency:
            let prefix = spend.amount < 0 ? "+" : ""
            return format(
                amount: -spend.localAmount,
                currencyCode: spend.localCurrency,
                prefix: prefix
            )
        case .spend, .collateral, .payment, .fee:
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

            return spend.merchantCategory?.orNilIfEmpty
                ?? spend.enrichedMerchantCategory?.orNilIfEmpty
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

// MARK: - TangemPayTransactionRecord+

extension TangemPayTransactionRecord {
    var transactionDate: Date {
        switch record {
        case .spend(let spend): spend.authorizedAt
        case .collateral(let collateral): collateral.postedAt
        case .payment(let payment): payment.postedAt
        case .fee(let fee): fee.postedAt
        }
    }
}

private extension String {
    static func merchantCategory(category: String, mcc: String) -> String {
        return category + " " + AppConstants.dotSign + " " + Localization.tangemPayHistoryItemSpendMcc(mcc)
    }

    var orNilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}
