//
//  SendTransactionHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk

class SendTransactionHandler: RequestHandler {
    private(set) weak var handler: WCSendTxHandler!
//    private(set) weak var builder: EthereumTransactionBuilder
    
    init(handler: WCSendTxHandler) {
        self.handler = handler
    }
    
    func canHandle(request: Request) -> Bool {
        return request.method == "eth_sendTransaction"
    }

    func handle(request: Request) {
        do {
            let transaction = try request.parameter(of: EthTransaction.self, at: 0)
            
            guard handler.assertAddress(transaction.from) else {
                handler.server.send(.reject(request))
                return
            }
            
            handler.askToMakeTx(request: request, ethTx: transaction)
        } catch {
            handler.server.send(.invalid(request))
        }
    }
}
