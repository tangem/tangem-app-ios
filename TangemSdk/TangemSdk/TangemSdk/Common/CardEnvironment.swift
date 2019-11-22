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
public struct CardEnvironment: Equatable {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    public var pin1: String = CardEnvironment.defaultPin1
    public var pin2: String = CardEnvironment.defaultPin2
    public var terminalKeys: KeyPair? = nil
    public var encryptionKey: Data? = nil
    
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    static var needLegacyMode: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier == "iPhone9,1" || identifier == "iPhone9,2" || identifier == "iPhone9,3" || identifier == "iPhone9,4"
    }
    
    public init() {
        
    }
}


//public protocol DataStorage {
//    func object(forKey: String) -> Any?
//    func set(_ value: Any, forKey: String)
//}
//
//enum DataStorageKey: String {
//    case terminalPrivateKey
//    case terminalPublicKey
//    case pin1
//    case pin2
//}

//public final class DefaultDataStorage: DataStorage {
//    public func object(forKey: String) -> Any? {
//        //[REDACTED_TODO_COMMENT]
//        return nil
//    }
//
//    public func set(_ value: Any, forKey: String) {
//        //[REDACTED_TODO_COMMENT]
//    }
//
//    public init() {
//    }
//}

//final class CardEnvironmentRepository {
//    var cardEnvironment: CardEnvironment {
//        didSet {
//            if cardEnvironment != oldValue {
//                save(cardEnvironment)
//            }
//        }
//    }
//
//    private let dataStorage: DataStorage?
//
//    init(dataStorage: DataStorage?) {
//        self.dataStorage = dataStorage
//
//        var environment = CardEnvironment()
//        if let storage = dataStorage {
//            if let pin1 = storage.object(forKey: DataStorageKey.pin1.rawValue) as? String {
//                environment.pin1 = pin1
//            }
//
//            if let pin2 = storage.object(forKey: DataStorageKey.pin2.rawValue) as? String {
//                environment.pin2 = pin2
//            }
//
//            if let terminalPrivateKey = storage.object(forKey: DataStorageKey.terminalPrivateKey.rawValue) as? Data,
//                let terminalPublicKey = storage.object(forKey: DataStorageKey.terminalPublicKey.rawValue) as? Data {
//                let keyPair = KeyPair(privateKey: terminalPrivateKey, publicKey: terminalPublicKey)
//                environment.terminalKeys = keyPair
//            }
//        }
//
//        self.cardEnvironment = environment
//    }
//
//    private func save(_ cardEnvironment: CardEnvironment) {
//        //[REDACTED_TODO_COMMENT]
//    }
//}
