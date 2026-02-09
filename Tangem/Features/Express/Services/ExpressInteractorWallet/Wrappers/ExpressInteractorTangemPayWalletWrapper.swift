//
//  ExpressInteractorTangemPayWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

typealias ExpressInteractorTangemPayWallet = ExpressInteractorSourceWallet

struct ExpressInteractorTangemPayWalletWrapper: ExpressInteractorTangemPayWallet {
    let id: WalletModelId
    let userWalletId: UserWalletId
    let tokenHeader: ExpressInteractorTokenHeader? = nil
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? = nil

    let isCustom: Bool = false
    let isMainToken: Bool = false
    let isExemptFee: Bool = true
    let defaultAddressString: String
    let availableBalanceProvider: any TokenBalanceProvider
    let transactionValidator: any ExpressTransactionValidator

    let expressTokenFeeProvidersManager: any ExpressTokenFeeProvidersManager
    let transactionDispatcherProvider: any TransactionDispatcherProvider

    let sendingRestrictions: SendingRestrictions? = .none
    let amountToCreateAccount: Decimal = .zero
    let allowanceService: (any AllowanceService)? = nil
    let withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? = nil
    let interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger

    private var _balanceProvider: any ExpressBalanceProvider
    private var _feeProvider: any ExpressFeeProvider

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        defaultAddressString: String,
        availableBalanceProvider: any TokenBalanceProvider,
        cexTransactionDispatcher: any TransactionDispatcher,
        transactionValidator: any ExpressTransactionValidator
    ) {
        id = .init(tokenItem: tokenItem)
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.defaultAddressString = defaultAddressString
        self.availableBalanceProvider = availableBalanceProvider
        self.transactionValidator = transactionValidator

        interactorAnalyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: tokenItem,
            feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder(isFixedFee: false)
        )

        expressTokenFeeProvidersManager = TangemPayExpressTokenFeeProvidersManager(tokenItem: tokenItem)
        transactionDispatcherProvider = TangemPayTransactionDispatcherProvider(cexTransactionDispatcher: cexTransactionDispatcher)

        _balanceProvider = TangemPayExpressBalanceProvider(
            availableBalanceProvider: availableBalanceProvider,
        )

        _feeProvider = TangemPayWithdrawExpressFeeProvider(
            feeTokenItem: feeTokenItem
        )
    }
}

// MARK: - ExpressSourceWallet, ExpressDestinationWallet

extension ExpressInteractorTangemPayWalletWrapper {
    var feeProvider: ExpressFeeProvider { _feeProvider }

    var balanceProvider: ExpressBalanceProvider { _balanceProvider }

    var operationType: ExpressOperationType { .swap }

    var supportedProvidersFilter: SupportedProvidersFilter { .cex }
}
