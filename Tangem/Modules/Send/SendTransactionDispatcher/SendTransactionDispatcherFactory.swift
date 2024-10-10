//
//  SendTransactionDispatcherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

struct SendTransactionDispatcherFactory {
    let walletModel: WalletModel
    let signer: TangemSigner

    func makeSendDispatcher() -> SendTransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return CommonSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
    }
}
