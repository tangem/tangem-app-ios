
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

public protocol TlvMapable {
    init?(from tlv: [Tlv])
}

@available(iOS 13.0, *)
public protocol CommandSerializer {
    associatedtype CommandResponse: TlvMapable
    
    func serialize(with environment: CardEnvironment) -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) -> CommandResponse?
}

@available(iOS 13.0, *)
public extension CommandSerializer {
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) -> CommandResponse? {
        guard let tlv = apdu.deserialize(encryptionKey: environment.encryptionKey),
            let commandResponse = CommandResponse(from: tlv) else {
                return nil
        }
        
        return commandResponse
    }
}
