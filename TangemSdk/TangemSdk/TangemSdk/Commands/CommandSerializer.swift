
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC


public protocol CommandSerializer {
    associatedtype CommandResponse
    
    func serialize(with environment: CardEnvironment) -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

public extension CommandSerializer {
    func deserializeSecurityDelay(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
}
