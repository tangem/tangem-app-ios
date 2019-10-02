
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

protocol TlvConvertible {
    init?(from tlv: [Tlv])
}

@available(iOS 13.0, *)
protocol Command {
    associatedtype CommandResult: TlvConvertible
    
    func serialize(with environment: CardEnvironment) -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) -> CommandResult?
}

@available(iOS 13.0, *)
extension Command {
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) -> CommandResult? {
        guard let tlv = apdu.deserialize(encryptionKey: environment.encryptionKey),
            let readResult = CommandResult(from: tlv) else {
                return nil
        }
        
        return readResult
    }
}

//MARK: Read command
typealias Card = ReadCardResult

struct ReadCardResult: TlvConvertible {
    init?(from tlv: [Tlv]) {
        return nil
    }
}

@available(iOS 13.0, *)
class ReadCardCommand: Command {
    typealias CommandResult = ReadCardResult
    
    init() {
        //[REDACTED_TODO_COMMENT]
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlv = [Tlv]()
        let cApdu = CommandApdu(.read, tlv: tlv)
        return cApdu
    }
}
