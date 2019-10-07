//
//  CheckWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct CheckWalletResponse: TlvMapable {
    init?(from tlv: [Tlv]) {
        //[REDACTED_TODO_COMMENT]
    }
}

@available(iOS 13.0, *)
class CheckWalletCommand: CommandSerializer {
    typealias CommandResponse = CheckWalletResponse
    
    init() {
             //[REDACTED_TODO_COMMENT]
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
       let tlv = [Tlv]()
        //[REDACTED_TODO_COMMENT]
        let cApdu = CommandApdu(.checkWallet, tlv: tlv)
        return cApdu
    }
}
