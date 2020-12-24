//
//  WarningEventManager.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class WarningEventManager {
    
    static let instance = WarningEventManager()
    
    @Storage(type: .oldDeviceOldCardAlert, defaultValue: false)
    private var oldDeviceOldCardShown: Bool
    
    @Storage(type: .scannedCards, defaultValue: [])
    private var scannedCards: [String]
    
    private init() { }
    
    func getAlert(_ alertType: WarningEvent, for card: Card) -> TapWarning? {
        if canShow(alertType, card: card) {
            return alertType.warning
        } else {
            return nil
        }
    }
    
    private func canShow(_ alertType: WarningEvent, card: Card) -> Bool {
        switch alertType {
        case .oldDeviceOldCard:
            guard let fw = card.firmwareVersionValue else {
                return false
            }
            
            guard fw < 2.28 else { //old cards
                return false
            }
            
            guard NfcUtils.isPoorNfcQualityDevice else { //old phone
                return false
            }
            
            guard !oldDeviceOldCardShown else {
                return false
            }
            
            oldDeviceOldCardShown = true
            return true
        case .numberOfSignedHashesIncorrect:
            guard let signedHashes = card.walletSignedHashes,
                let cid = card.cardId else {
                    return false
            }
            
            let scannedCards = self.scannedCards
//            if scannedCards.contains(cid) {
//                return false
//            }
            
            if signedHashes == 0 {
                return false
            }
            
            self.scannedCards = scannedCards + [cid]
            return true
            
        case .devCard:
            guard let cid = card.cardId else {
                return false
            }
            
            let scannedCards = self.scannedCards
//            if scannedCards.contains(cid) {
//                return false
//            }
            
            self.scannedCards = scannedCards + [cid]
            return true
        }
    }
    
}
