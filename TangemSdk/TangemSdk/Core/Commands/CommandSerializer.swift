
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

@available(iOS 13.0, *)
public protocol CommandSerializer {
    associatedtype CommandResponse: TlvMappable
    
    func serialize(with environment: CardEnvironment) throws -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

@available(iOS 13.0, *)
public extension CommandSerializer {
    func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> CommandResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        return try CommandResponse(from: tlv)
    }
}
