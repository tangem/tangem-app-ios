//
//  TransactionDispatcherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

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

    func makeYieldModuleDispatcher() -> YieldModuleTransactionDispatcher? {
        guard let transactionsSender = walletModel.multipleTransactionsSender else { return nil }

        return YieldModuleTransactionDispatcher(
            blockchain: walletModel.tokenItem.blockchain,
            walletModelUpdater: walletModel,
            transactionsSender: transactionsSender,
            transactionSigner: signer
        )
    }
}
