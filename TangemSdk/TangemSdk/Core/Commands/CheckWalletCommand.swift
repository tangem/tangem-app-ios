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
        <#code#>
    }
}

@available(iOS 13.0, *)
class CheckWalletCommand: Command {
    typealias CommandResponse = CheckWalletResponse
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        <#code#>
    }
}
