//
//  PersonalSignHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

class PersonalSignHandler: WalletConnectSignHandler {
    
    override func canHandle(request: Request) -> Bool {
        return request.method == "personal_sign"
    }

    override func handle(request: Request) {
        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)
            let address = try request.parameter(of: String.self, at: 1)

            guard let session = dataSource?.session(for: request, address: address) else {
                delegate?.send(.reject(request))
                return
            }
        
            let prefix = "Message for \(session.session.dAppInfo.peerMeta.name):\n"
            let message = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes
            let personalMessageData = self.makePersonalMessageData(Data(hex: messageBytes))
            askToSign(in: session, request: request, message: prefix + message, dataToSign: personalMessageData)
        } catch {
            delegate?.send(.invalid(request))
        }
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}

