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

    private let _feeProvider: any TangemExpress.FeeProvider
    private let _allowanceService: any AllowanceService
    private let _balanceProvider: any TangemExpress.BalanceProvider

    private let _transactionBuilder: any ExpressTransactionBuilder

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel

        _feeProvider = CommonExpressFeeProvider(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeProvider: walletModel,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider
        )

        _allowanceService = CommonAllowanceService(
            tokenItem: walletModel.tokenItem,
            allowanceChecker: .init(
                blockchain: walletModel.tokenItem.blockchain,
                amountType: walletModel.tokenItem.amountType,
                walletAddress: walletModel.defaultAddressString,
                ethereumNetworkProvider: walletModel.ethereumNetworkProvider,
                ethereumTransactionDataBuilder: walletModel.ethereumTransactionDataBuilder
            )
        )

        _balanceProvider = CommonExpressBalanceProvider(
            tokenItem: walletModel.tokenItem,
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )

        _transactionBuilder = CommonExpressTransactionBuilder(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            transactionCreator: walletModel.transactionCreator,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider
        )
    }
}

// MARK: - ExpressInteractorSourceWallet

extension ExpressInteractorWalletWrapper: ExpressInteractorSourceWallet {
    var id: WalletModelId { walletModel.id }
    var isCustom: Bool { walletModel.isCustom }
    var isMainToken: Bool { walletModel.isMainToken }

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

    var allowanceService: any AllowanceService { _allowanceService }
    var availableBalanceProvider: any TokenBalanceProvider { walletModel.availableBalanceProvider }
    var transactionValidator: any TransactionValidator { walletModel.transactionValidator }
    var expressTransactionBuilder: any ExpressTransactionBuilder { _transactionBuilder }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { walletModel.withdrawalNotificationProvider }

    func transactionDispatcher(signer: TangemSigner) -> any TransactionDispatcher {
        TransactionDispatcherFactory(walletModel: walletModel, signer: signer).makeSendDispatcher()
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        walletModel.exploreTransactionURL(for: hash)
    }
}

// MARK: - ExpressSourceWallet

extension ExpressInteractorWalletWrapper: ExpressSourceWallet {
    var address: String? { walletModel.defaultAddress.value }
    var currency: TangemExpress.ExpressWalletCurrency { tokenItem.expressCurrency }
    var feeCurrency: TangemExpress.ExpressWalletCurrency { feeTokenItem.expressCurrency }

    var feeProvider: any TangemExpress.FeeProvider { _feeProvider }
    var allowanceProvider: any TangemExpress.AllowanceProvider { _allowanceService }
    var balanceProvider: any TangemExpress.BalanceProvider { _balanceProvider }
}

// MARK: - ExpressInteractorDestinationWallet

extension ExpressInteractorWalletWrapper: ExpressInteractorDestinationWallet {}
