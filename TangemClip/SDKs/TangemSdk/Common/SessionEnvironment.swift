//
//  SessionEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

//All encryption modes
public enum EncryptionMode: Byte {
    case none = 0x00
    case fast = 0x01
    case strong = 0x02
}

public struct KeyPair: Equatable, Codable {
    public let privateKey: Data
    public let publicKey: Data
}

public struct PinCode {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    public enum PinType {
        case pin1
        case pin2
    }
    
    let type: PinType
    let value: Data?
    
    var isDefault: Bool {
        switch type {
        case .pin1:
            return PinCode.defaultPin1.sha256() == value
        case .pin2:
            return PinCode.defaultPin2.sha256() == value
        }
    }

    internal init(_ type: PinType) {
        switch type {
        case .pin1:
            self.value = PinCode.defaultPin1.sha256()
        case .pin2:
            self.value = PinCode.defaultPin2.sha256()
        }
        self.type = type
    }
    
    internal init(_ type: PinType, stringValue: String) {
        self.value = stringValue.sha256()
        self.type = type
    }
    
    internal init(_ type: PinType, value: Data?) {
        self.value = value
        self.type = type
    }
}

/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `SessionEnvironment`.
public struct SessionEnvironment {    
    /// Current card, read by preflight `Read` command
    public var card: Card? = nil
    
    /// Keys for Linked Terminal feature
    public var terminalKeys: KeyPair? = nil
    
    public var encryptionMode: EncryptionMode = .none
    
    public var encryptionKey: Data? = nil
    
    public var cvc: Data? = nil
    
    var legacyMode: Bool = true
    
    public var allowedCardTypes: [FirmwareType] = [.sdk, .release, .special]
    
    public var handleErrors: Bool = true
    
    var pin1: PinCode = PinCode(.pin1)
    
    var pin2: PinCode = PinCode(.pin2)
    
    public init() {}
}
