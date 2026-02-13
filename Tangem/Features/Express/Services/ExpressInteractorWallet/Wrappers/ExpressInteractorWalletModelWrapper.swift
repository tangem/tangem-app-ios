//
//  ExpressInteractorWalletModelWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation
import BlockchainSdk

struct ExpressInteractorWalletModelWrapper {
    let id: WalletModelId
    let userWalletId: UserWalletId
    let isCustom: Bool
    let isMainToken: Bool
    let isExemptFee: Bool = false

    let tokenHeader: ExpressInteractorTokenHeader?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let defaultAddressString: String

    let tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider
    let transactionDispatcherProvider: TransactionDispatcherProvider

    let availableBalanceProvider: any TokenBalanceProvider
    let transactionValidator: any ExpressTransactionValidator
    let withdrawalNotificationProvider: (any WithdrawalNotificationProvider)?
    let interactorAnalyticsLogger: any ExpressInteractorAnalyticsLogger

    private let walletModel: any WalletModel
    private let expressOperationType: ExpressOperationType

    private let _allowanceService: (any AllowanceService)?
    private let _balanceProvider: any ExpressBalanceProvider

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        expressOperationType: ExpressOperationType
    ) {
        self.walletModel = walletModel
        self.expressOperationType = expressOperationType

        id = walletModel.id
        userWalletId = userWalletInfo.id
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
        interactorAnalyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: .init(isFixedFee: !walletModel.shouldShowFeeSelector)
        )

        transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )

        tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .swap
        )

        _allowanceService = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcherProvider: transactionDispatcherProvider
        ).makeAllowanceService()

        _balanceProvider = CommonExpressBalanceProvider(
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )
    }
}

// MARK: - ExpressInteractorSourceWallet

extension ExpressInteractorWalletModelWrapper: ExpressInteractorSourceWallet {
    var extraId: String? {
        // Source wallets don't use memo fields on Tangem addresses
        .none
    }

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
        case .swapAndSend where FeatureProvider.isAvailable(.exchangeOnlyWithinSingleAddress):
            return .byDifferentAddressExchangeSupport
        case .swapAndSend:
            return .cex
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
}

// MARK: - ExpressSourceWallet

extension ExpressInteractorWalletModelWrapper {
    var balanceProvider: any ExpressBalanceProvider { _balanceProvider }
    var operationType: ExpressOperationType { expressOperationType }
}
