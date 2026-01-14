//
//  TransactionDispatcherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

struct TransactionDispatcherFactory {
    let walletModel: any WalletModel
    let signer: TangemSigner

    func makeSendDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        let gaslessTransactionBuilder = GaslessTransactionBuilder(walletModel: walletModel, signer: signer)
        let gaslessTransactionBroadcastService = GaslessTransactionBroadcastService(
            walletModel: walletModel,
            transactionSigner: signer,
            gaslessTransactionBuilder: gaslessTransactionBuilder
        )
        return SendTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            gaslessTransactionBroadcastService: gaslessTransactionBroadcastService
        )
    }

    func makeExpressDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return ExpressTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            sendTransactionDispatcher: makeSendDispatcher()
        )
    }

    func makeStakingTransactionDispatcher(
        stakingManger: some StakingManager,
        analyticsLogger: any StakingAnalyticsLogger
    ) -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
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

    func makeYieldModuleDispatcher() -> TransactionDispatcher? {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        guard let transactionsSender = walletModel.multipleTransactionsSender else { return nil }

        return YieldModuleTransactionDispatcher(
            blockchain: walletModel.tokenItem.blockchain,
            walletModelUpdater: walletModel,
            transactionsSender: transactionsSender,
            transactionSigner: signer,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }
}
