//
//  CardEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct CardEnvironment {
    let pin1: String = "000000"
    let pin2: String = "000"
    let terminalPrivateKey: Data?
    let terminalPublicKey: Data?
    let encryptionKey: Data?
}
