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
    var id: WalletModelId { get }
    var isCustom: Bool { get }
    var isMainToken: Bool { get }

    /// Applicable only for `TangemPay` because there is no fee for withdraw
    var isExemptFee: Bool { get }

    var tokenHeader: ExpressInteractorTokenHeader? { get }
    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }

    var defaultAddressString: String { get }
    var sendingRestrictions: SendingRestrictions? { get }
    var amountToCreateAccount: Decimal { get }

    var expressTokenFeeManager: ExpressTokenFeeManager { get }
    var allowanceService: (any AllowanceService)? { get }
    var availableBalanceProvider: TokenBalanceProvider { get }
    var transactionValidator: any ExpressTransactionValidator { get }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { get }
    var interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger { get }

    func dexTransactionProcessor() throws -> ExpressDEXTransactionProcessor
    func cexTransactionProcessor() throws -> ExpressCEXTransactionProcessor
}

// MARK: ExpressSourceWallet + ExpressInteractorSourceWallet

extension ExpressSourceWallet where Self: ExpressInteractorSourceWallet {
    var address: String? { defaultAddressString }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var analyticsLogger: ExpressAnalyticsLogger { interactorAnalyticsLogger }
}
