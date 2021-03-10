//
//  ValidatedCardsService.swift
//  Tangem Tap
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
    
    init() {
        keychain = KeychainSwift()
        keychain.synchronizable = true
    }
    
    func isCardValidated(_ card: Card) -> Bool {
        guard let data = card.cardValidationData else {
            return false
        }
        
        return keychain.get(validatedCardPrefix + data.cid) == data.pubKey
    }
    
    func saveValidatedCard(_ card: Card) {
        guard let data = card.cardValidationData else { return }
        
        keychain.set(data.pubKey, forKey: validatedCardPrefix + data.cid)
    }
    
    func pubkey(for cid: String) -> String? {
        keychain.get(validatedCardPrefix + cid)
    }
    
}
