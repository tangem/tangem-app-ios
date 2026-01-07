//
//  ExpressInteractorWalletModelWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct ExpressInteractorWalletModelWrapper {
    let id: WalletModelId
    let isCustom: Bool
    let isMainToken: Bool
    let isExemptFee: Bool = false

    let tokenHeader: ExpressInteractorTokenHeader?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let defaultAddressString: String

    let availableBalanceProvider: any TokenBalanceProvider
    let transactionValidator: any ExpressTransactionValidator
    let withdrawalNotificationProvider: (any WithdrawalNotificationProvider)?
    let interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger
    var tokenFeeProvider: any TokenFeeProvider { _feeProvider }

    private let walletModel: any WalletModel
    private let expressOperationType: ExpressOperationType

    private let transactionProcessorFactory: ExpressTransactionProcessorFactory
    private let allowanceServiceFactory: AllowanceServiceFactory

    private let _allowanceService: (any AllowanceService)?
    private let _feeProvider: CommonExpressFeeProvider
    private let _balanceProvider: any ExpressBalanceProvider

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        expressOperationType: ExpressOperationType
    ) {
        self.walletModel = walletModel
        self.expressOperationType = expressOperationType

        id = walletModel.id
        isCustom = walletModel.isCustom
        isMainToken = walletModel.isMainToken

        let headerProvider = ExpressInteractorTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account
        )
        tokenHeader = headerProvider.makeHeader()
        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        defaultAddressString = walletModel.defaultAddressString

        availableBalanceProvider = walletModel.availableBalanceProvider
        transactionValidator = BSDKExpressTransactionValidator(transactionValidator: walletModel.transactionValidator)
        withdrawalNotificationProvider = walletModel.withdrawalNotificationProvider
        interactorAnalyticsLogger = CommonExpressInteractorAnalyticsLogger(tokenItem: walletModel.tokenItem)

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        ).makeExpressDispatcher()

        allowanceServiceFactory = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcher: transactionDispatcher,
        )

        transactionProcessorFactory = ExpressTransactionProcessorFactory(
            walletModel: walletModel,
            transactionDispatcher: transactionDispatcher,
        )

        _allowanceService = allowanceServiceFactory.makeAllowanceService()

        _feeProvider = CommonExpressFeeProvider(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeLoader: walletModel.tokenFeeLoader,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider
        )

        _balanceProvider = CommonExpressBalanceProvider(
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )
    }
}

// MARK: - ExpressInteractorSourceWallet

extension ExpressInteractorWalletModelWrapper: ExpressInteractorSourceWallet {
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? {
        walletModel.account
    }

    var supportedProvidersFilter: SupportedProvidersFilter {
        let isYieldModuleActive = walletModel.yieldModuleManager?.state?.state.isActive == true

        switch expressOperationType {
        case .onramp:
            return .onramp
        case .swapAndSend where isYieldModuleActive,
             .swap where isYieldModuleActive:
            return .cex
        case .swapAndSend:
            return .byDifferentAddressExchangeSupport
        case .swap:
            return .swap
        }
    }

    var sendingRestrictions: SendingRestrictions? {
        walletModel.sendingRestrictions
    }

    var amountToCreateAccount: Decimal {
        if case .noAccount(_, let amount) = walletModel.state {
            return amount
        }

        return 0
    }

    var allowanceService: (any AllowanceService)? { _allowanceService }

    func cexTransactionProcessor() throws -> any ExpressCEXTransactionProcessor {
        return try transactionProcessorFactory.makeCEXTransactionProcessor()
    }

    func dexTransactionProcessor() throws -> any ExpressDEXTransactionProcessor {
        return try transactionProcessorFactory.makeDEXTransactionProcessor()
    }
}

// MARK: - ExpressSourceWallet

extension ExpressInteractorWalletModelWrapper {
    var feeProvider: any ExpressFeeProvider { _feeProvider }
    var balanceProvider: any ExpressBalanceProvider { _balanceProvider }
    var operationType: ExpressOperationType { expressOperationType }
}
