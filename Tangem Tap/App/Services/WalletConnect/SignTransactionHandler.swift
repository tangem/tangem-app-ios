//
//  SignTransactionHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

class SignTransactionHandler: RequestHandler {
    private(set) weak var handler: SignHandler!
    
    init(handler: SignHandler) {
        self.handler = handler
    }
    
    func canHandle(request: Request) -> Bool {
        return request.method == "eth_signTransaction"
    }

    func handle(request: Request) {
        do {
            let transaction = try request.parameter(of: EthTransaction.self, at: 0)
            
            guard handler.assertAddress(transaction.from) else {
                handler.server.send(.reject(request))
                return
            }
            
            let message = transaction.description
            let data = Data(hex: transaction.data)
            handler.askToSign(request: request, message: message, dataToSign: data)
        } catch {
            handler.server.send(.invalid(request))
        }
    }
}
