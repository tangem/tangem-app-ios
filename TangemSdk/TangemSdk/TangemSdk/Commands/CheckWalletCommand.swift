//
//  CheckWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct CheckWalletResponse {
    let cardId: String
    let salt: Data
    let walletSignature: Data
}

@available(iOS 13.0, *)
public final class CheckWalletCommand: CommandSerializer {
    public typealias CommandResponse = CheckWalletResponse
    
    let pin1: String
    let cardId: String
    let challenge: Data
    
    
    public init(pin1: String, cardId: String, challenge: Data) {
        self.pin1 = pin1
        self.cardId = cardId
        self.challenge = challenge
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId)),
                       Tlv(.challenge, value: challenge)]
        
        let cApdu = CommandApdu(.checkWallet, tlv: tlvData)
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> CheckWalletResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return CheckWalletResponse(
            cardId: try mapper.map(.cardId),
            salt: try mapper.map(.salt),
            walletSignature: try mapper.map(.walletSignature))
    }
}
