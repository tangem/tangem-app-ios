//
//  CardEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct CardEnvironment {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    let pin1: String = defaultPin1
    let pin2: String = defaultPin2
    let terminalPrivateKey: Data? = nil
    let terminalPublicKey: Data? = nil
    let encryptionKey: Data? = nil
}
