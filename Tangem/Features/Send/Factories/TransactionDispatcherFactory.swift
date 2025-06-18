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
    let signer: TransactionSigner

    func makeSendDispatcher() -> TransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return SendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
    }
}
