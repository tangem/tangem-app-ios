//
//  PersonalSignHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

class PersonalSignHandler: RequestHandler {
    private(set) weak var handler: SignHandler!
    
    init(handler: SignHandler) {
        self.handler = handler
    }
    
    func canHandle(request: Request) -> Bool {
        return request.method == "personal_sign"
    }

    func handle(request: Request) {
        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)
            let address = try request.parameter(of: String.self, at: 1)

            guard handler.assertAddress(address) else {
                handler.server.send(.reject(request))
                return
            }
        
            let message = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes
            let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
            handler.askToSign(request: request, address: address, message: message, dataToSign: personalMessageData)
        } catch {
            handler.server.send(.invalid(request))
            return
        }
    }

    private func personalMessageData(messageData: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
        return prefixData + messageData
    }
}
