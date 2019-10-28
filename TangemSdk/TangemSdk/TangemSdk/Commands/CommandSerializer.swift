
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol TlvMappable {
    init(from tlv: [Tlv]) throws
}

public protocol CommandSerializer {
    associatedtype CommandResponse: TlvMappable
    
    func serialize(with environment: CardEnvironment) -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

public extension CommandSerializer {
    func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> CommandResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        return try CommandResponse(from: tlv)
    }
    
    func deserializeSecurityDelay(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
}
