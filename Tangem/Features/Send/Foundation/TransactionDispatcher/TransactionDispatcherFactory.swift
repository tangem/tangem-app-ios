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

        return SendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
    }

    func makeExpressDispatcher() -> TransactionDispatcher {
        ExpressTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            sendTransactionDispatcher: makeSendDispatcher()
        )
    }

    func makeStakingTransactionDispatcher(
        stakingManger: some StakingManager,
        analyticsLogger: any StakingAnalyticsLogger
    ) -> TransactionDispatcher {
        StakingTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            pendingHashesSender: StakingDependenciesFactory().makePendingHashesSender(),
            stakingTransactionMapper: StakingTransactionMapper(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            ),
            analyticsLogger: analyticsLogger,
            transactionStatusProvider: CommonStakeKitTransactionStatusProvider(stakingManager: stakingManger)
        )
    }
}
