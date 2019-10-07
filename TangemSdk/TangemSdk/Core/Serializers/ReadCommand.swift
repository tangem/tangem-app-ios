//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias Card = ReadResponse

public struct ReadResponse: TlvMapable {
    public init?(from tlv: [Tlv]) {
        return nil
        //[REDACTED_TODO_COMMENT]
    }
}

@available(iOS 13.0, *)
public class ReadCommand: CommandSerializer {
    public typealias CommandResponse = ReadResponse
    
    init() {
        //[REDACTED_TODO_COMMENT]
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlv = [Tlv]()
        //[REDACTED_TODO_COMMENT]
        let cApdu = CommandApdu(.read, tlv: tlv)
        return cApdu
    }
}
