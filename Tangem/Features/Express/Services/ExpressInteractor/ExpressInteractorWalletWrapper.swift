//
//  ExpressInteractorWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct ExpressInteractorWalletWrapper {
    private let walletModel: any WalletModel

    private let transactionProcessorFactory: ExpressTransactionProcessorFactory
    private let allowanceServiceFactory: AllowanceServiceFactory

    private let _feeProvider: any TangemExpress.FeeProvider
    private let _allowanceService: (any AllowanceService)?
    private let _balanceProvider: any TangemExpress.BalanceProvider

    init(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) {
        self.walletModel = walletModel

        _feeProvider = CommonExpressFeeProvider(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeProvider: walletModel,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider
        )

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

        _balanceProvider = CommonExpressBalanceProvider(
            tokenItem: walletModel.tokenItem,
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )
    }
}

// MARK: - ExpressInteractorSourceWallet

extension ExpressInteractorWalletWrapper: ExpressInteractorSourceWallet {
    var id: WalletModelId { walletModel.id }
    var isCustom: Bool { walletModel.isCustom }
    var isMainToken: Bool { walletModel.isMainToken }
    var supportedProviders: [ExpressProviderType] {
        if case .active? = walletModel.yieldModuleManager?.state?.state { .yieldActive } else { .swap }
    }

    var tokenItem: TokenItem { walletModel.tokenItem }
    var feeTokenItem: TokenItem { walletModel.feeTokenItem }

    var defaultAddressString: String { walletModel.defaultAddressString }
    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? { walletModel.sendingRestrictions }
    var amountToCreateAccount: Decimal {
        if case .noAccount(_, let amount) = walletModel.state {
            return amount
        }

        return 0
    }

    var allowanceService: (any AllowanceService)? { _allowanceService }
    var availableBalanceProvider: any TokenBalanceProvider { walletModel.availableBalanceProvider }
    var transactionValidator: any TransactionValidator { walletModel.transactionValidator }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { walletModel.withdrawalNotificationProvider }

    func cexTransactionProcessor() throws -> any ExpressCEXTransactionProcessor {
        return try transactionProcessorFactory.makeCEXTransactionProcessor()
    }

    func dexTransactionProcessor() throws -> any ExpressDEXTransactionProcessor {
        return try transactionProcessorFactory.makeDEXTransactionProcessor()
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        walletModel.exploreTransactionURL(for: hash)
    }
}

// MARK: - ExpressSourceWallet

extension ExpressInteractorWalletWrapper: ExpressSourceWallet {
    var address: String? { walletModel.defaultAddress.value }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }

    var feeProvider: any ExpressFeeProvider { _feeProvider }
    var allowanceProvider: (any ExpressAllowanceProvider)? { _allowanceService }
    var balanceProvider: any ExpressBalanceProvider { _balanceProvider }
}

// MARK: - ExpressInteractorDestinationWallet

extension ExpressInteractorWalletWrapper: ExpressInteractorDestinationWallet {}
