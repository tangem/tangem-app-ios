//
//  CheckWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct CheckWalletResponse: TlvMapable {
    let cardId: String
    let salt: Data
    let walletSignature: Data
    
    init?(from tlv: [Tlv]) {
        guard let cardIdData = tlv.value(for: .cardId),
            let saltData = tlv.value(for: .salt),
            let walletSignature = tlv.value(for: .walletSignature) else {
                return nil
        }
        
        self.cardId = cardIdData.toHexString()
        self.salt = saltData
        self.walletSignature = walletSignature
    }
}

@available(iOS 13.0, *)
class CheckWalletCommand: CommandSerializer {
    typealias CommandResponse = CheckWalletResponse
    
    let pin1: String
    let cardId: String
    let challenge: Data
    
    init(pin1: String, cardId: String, challenge: Data) {
        self.pin1 = pin1
        self.cardId = cardId
        self.challenge = challenge
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId)),
                       Tlv(.challenge, value: challenge)]
        
        let cApdu = CommandApdu(.checkWallet, tlv: tlvData)
        return cApdu
    }
}
