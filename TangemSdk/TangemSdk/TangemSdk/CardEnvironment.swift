//
//  CardEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

//All encryption modes
public enum EncryptionMode: Byte {
    case none = 0x0
    case fast = 0x1
    case strong = 0x2
}

public struct KeyPair: Equatable {
    public let privateKey: Data
    public let publicKey: Data
}


/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `CardEnvironment`.
public struct CardEnvironment {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    public var card: Card? = nil
    public var pin1: String = CardEnvironment.defaultPin1
    public var pin2: String = CardEnvironment.defaultPin2
    public var terminalKeys: KeyPair? = nil
    public var encryptionKey: Data? = nil
    public var legacyMode: Bool = true
    public var cvc: Data? = nil
    
    public init() {}
}
