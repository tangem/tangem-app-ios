//
//  SignTransactionHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

class SignTransactionHandler: WalletConnectSignHandler {
    
    override func canHandle(request: Request) -> Bool {
        return request.method == "eth_signTransaction"
    }

    override func handle(request: Request) {
        do {
            let transaction = try request.parameter(of: WalletConnectEthTransaction.self, at: 0)
            
            guard let session = dataSource?.session(for: request, address: transaction.from) else {
                delegate?.sendReject(for: request)
                return
            }
            
            let message = transaction.description
            let data = Data(hex: transaction.data)
            askToSign(in: session, request: request, message: message, dataToSign: data)
        } catch {
            delegate?.send(.invalid(request))
        }
    }
}
