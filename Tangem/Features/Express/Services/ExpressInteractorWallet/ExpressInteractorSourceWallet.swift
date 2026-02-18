//
//  ExpressInteractorSourceWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

protocol ExpressInteractorSourceWallet: ExpressInteractorDestinationWallet, ExpressSourceWallet {
    var isMainToken: Bool { get }

    /// Applicable only for `TangemPay` because there is no fee for withdraw
    var isExemptFee: Bool { get }

    var feeTokenItem: TokenItem { get }

    var defaultAddressString: String { get }
    var sendingRestrictions: SendingRestrictions? { get }
    var amountToCreateAccount: Decimal { get }

    var tokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider { get }
    var transactionDispatcherProvider: TransactionDispatcherProvider { get }

    var allowanceService: (any AllowanceService)? { get }
    var availableBalanceProvider: TokenBalanceProvider { get }
    var transactionValidator: any ExpressTransactionValidator { get }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { get }
    var interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger { get }
}

// MARK: ExpressSourceWallet + ExpressInteractorSourceWallet

extension ExpressSourceWallet where Self: ExpressInteractorSourceWallet {
    var address: String? { defaultAddressString }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var analyticsLogger: ExpressAnalyticsLogger { interactorAnalyticsLogger }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { tokenFeeProvidersManagerProvider }
}
