//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

typealias Card = ReadResponse

struct ReadResponse: TlvMapable {
    init?(from tlv: [Tlv]) {
        return nil
    }
}

@available(iOS 13.0, *)
class ReadCommand: Command {
    typealias CommandResponse = ReadResponse
    
    init() {
        //[REDACTED_TODO_COMMENT]
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlv = [Tlv]()
        let cApdu = CommandApdu(.read, tlv: tlv)
        return cApdu
    }
}
