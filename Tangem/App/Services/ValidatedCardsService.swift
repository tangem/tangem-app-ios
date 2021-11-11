//
//  ValidatedCardsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import KeychainSwift
import TangemSdk

class ValidatedCardsService {
    
    private let keychain: KeychainSwift
    
    private let validatedCardPrefix = "validated_"
    
    init(keychain: KeychainSwift) {
        self.keychain = keychain
    }
    
    deinit {
        print("ValidatedCardsService deinit")
    }
    
    func clean() {
        let allKeys = keychain.allKeys
        let validatedKeys = allKeys.filter { $0.starts(with: validatedCardPrefix )}
        
        validatedKeys.forEach { key in
            keychain.delete(key)
        }
    }
    
//    func isCardValidated(_ card: Card) -> Bool {
//        return keychain.get(validatedCardPrefix + card.cardId) == card.cardPublicKey.hexString
//    }
//
//    func saveValidatedCard(_ card: Card) {
//        keychain.set(card.cardPublicKey.hexString, forKey: validatedCardPrefix + card.cardId)
//    }
    
//    func pubkey(for cid: String) -> String? {
//        keychain.get(validatedCardPrefix + cid)
//    }
    
}
