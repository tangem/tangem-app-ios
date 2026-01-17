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

typealias ExpressInteractorTangemPayWallet = ExpressInteractorSourceWallet

struct ExpressInteractorTangemPayWalletWrapper: ExpressInteractorTangemPayWallet {
    let id: WalletModelId
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
    let sendingRestrictions: SendingRestrictions? = .none
    let amountToCreateAccount: Decimal = .zero
    let allowanceService: (any AllowanceService)? = nil
    let withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? = nil
    let interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger

    private let _cexTransactionProcessor: any ExpressCEXTransactionProcessor
    private var _balanceProvider: any ExpressBalanceProvider
    private var _feeProvider: any ExpressFeeProvider

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        defaultAddressString: String,
        availableBalanceProvider: any TokenBalanceProvider,
        cexTransactionProcessor: any ExpressCEXTransactionProcessor,
        transactionValidator: any ExpressTransactionValidator
    ) {
        id = .init(tokenItem: tokenItem)

        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.defaultAddressString = defaultAddressString
        self.availableBalanceProvider = availableBalanceProvider
        self.transactionValidator = transactionValidator

        interactorAnalyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: tokenItem
        )

        expressTokenFeeProvidersManager = TangemPayExpressTokenFeeProvidersManager(tokenItem: tokenItem)
        _cexTransactionProcessor = cexTransactionProcessor

        _balanceProvider = TangemPayExpressBalanceProvider(
            availableBalanceProvider: availableBalanceProvider,
        )

        _feeProvider = TangemPayWithdrawExpressFeeProvider(
            feeTokenItem: feeTokenItem
        )
    }
}

extension ExpressInteractorTangemPayWalletWrapper {
    func cexTransactionProcessor() throws -> any ExpressCEXTransactionProcessor {
        _cexTransactionProcessor
    }

    func dexTransactionProcessor() throws -> any ExpressDEXTransactionProcessor {
        throw ExpressTransactionProcessorFactory.Error.dexNotSupported(blockchain: "Visa")
    }
}

// MARK: - ExpressSourceWallet, ExpressDestinationWallet

extension ExpressInteractorTangemPayWalletWrapper {
    var feeProvider: ExpressFeeProvider { _feeProvider }

    var balanceProvider: ExpressBalanceProvider { _balanceProvider }

    var operationType: ExpressOperationType { .swap }

    var supportedProvidersFilter: SupportedProvidersFilter { .cex }
}
