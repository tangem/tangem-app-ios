//
//  CardEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct KeyPair {
    let privateKey: Data
    let publicKey: Data
}

public struct CardEnvironment {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    let pin1: String
    let pin2: String
    let terminalKeys: KeyPair?
    let encryptionKey: Data?
}

public protocol DataStorage {
    func getTerminalPublicKey() -> Data?
    func getTerminalPrivateKey() -> Data?
    func getPin1() -> String?
    func getPin2() -> String?
    
    func storeTerminalPublicKey(_ data: Data)
    func storeTerminalPrivateKey(_ data: Data)
    func storePin1(_ string: String)
    func storePin2(_ string: String)
}

class CardEnvironmentRepository {
    var cardEnvironment: CardEnvironment {
        didSet {
            if cardEnvironment == oldValue {
                save(cardEnvironment)
            }
        }
    }
        
    private var encryptionKey: Data? = nil
    private let dataStorage: DataStorage
    
    init(dataStorage: DataStorage) {
        self.dataStorage = dataStorage
        self.cardEnvironment = CardEnvironment(pin1: dataStorage.getPin1() ?? CardEnvironment.defaultPin1,
                                               pin2: dataStorage.getPin2() ?? CardEnvironment.defaultPin2,
                                               terminalKeys: getTerminalKeys(),
                                               encryptionKey: self.encryptionKey)
    }
    
    private func getTerminalKeys() -> KeyPair? {
        if let terminalPrivateKey = dataStorage.getTerminalPrivateKey(),
            let terminalPublicKey = dataStorage.getTerminalPublicKey() {
            return KeyPair(privateKey: terminalPrivateKey, publicKey: terminalPublicKey)
        }
        return nil
    }
    
    private func save(_ cardEnvironment: CardEnvironment) {
        //[REDACTED_TODO_COMMENT]
    }
}
