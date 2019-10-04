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
    }
}

@available(iOS 13.0, *)
public class ReadCommand: Command {
    public typealias CommandResponse = ReadResponse
    
    init() {
        //[REDACTED_TODO_COMMENT]
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlv = [Tlv]()
        let cApdu = CommandApdu(.read, tlv: tlv)
        return cApdu
    }
}
