//
//  WalletModelTransactionDispatcherProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

struct WalletModelTransactionDispatcherProvider {
    let walletModel: any WalletModel
    let signer: TangemSigner
}

// MARK: - TransactionDispatcherProvider

extension WalletModelTransactionDispatcherProvider: TransactionDispatcherProvider {
    func makeTransferTransactionDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        let gaslessTransactionBuilder = GaslessTransactionBuilder(walletModel: walletModel, signer: signer)
        let gaslessTransactionSender = GaslessTransactionSender(
            walletModel: walletModel,
            transactionSigner: signer,
            gaslessTransactionBuilder: gaslessTransactionBuilder
        )
        return TransferTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            gaslessTransactionSender: gaslessTransactionSender
        )
    }

    func makeApproveTransactionDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return ApproveTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            transferTransactionDispatcher: makeTransferTransactionDispatcher()
        )
    }

    func makeDEXTransactionDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return ExpressDEXTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            transferTransactionDispatcher: makeTransferTransactionDispatcher()
        )
    }

    func makeCEXTransactionDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return ExpressCEXTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            transferTransactionDispatcher: makeTransferTransactionDispatcher()
        )
    }

    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        let mapper = StakingTransactionMapper(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )

        switch (walletModel.tokenItem.blockchain, walletModel.tokenItem.token) {
        case (.ethereum, .none):
            return P2PTransactionDispatcher(
                walletModel: walletModel,
                transactionSigner: signer,
                mapper: mapper,
                apiProvider: StakingDependenciesFactory().makeP2PAPIProvider()
            )
        default:
            return StakeKitTransactionDispatcher(
                walletModel: walletModel,
                transactionSigner: signer,
                pendingHashesSender: StakingDependenciesFactory().makePendingHashesSender(),
                stakingTransactionMapper: mapper,
                analyticsLogger: analyticsLogger,
                transactionStatusProvider: CommonStakeKitTransactionStatusProvider(
                    apiProvider: StakingDependenciesFactory().makeStakeKitAPIProvider()
                )
            )
        }
    }

    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoTransferTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return YieldModuleTransactionDispatcher(
            tokenItem: walletModel.tokenItem,
            walletModelUpdater: walletModel,
            transactionsSender: walletModel.multipleTransactionsSender,
            transactionSigner: signer,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }
}
