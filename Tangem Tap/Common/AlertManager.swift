//
//  AlertManager.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

class AlertManager {
    enum AlertType {
        case oldDeviceOldCard
        case untrustedCard
        case devCard
        
        private var alertMessage: LocalizedStringKey {
            switch self {
            case .oldDeviceOldCard:
                return "alert_old_device_this_card"
            case .untrustedCard:
                return "alert_card_signed_transactions"
            case .devCard:
                return "alert_developer_card"
            }
        }
        
        fileprivate var alert: Alert {
            return Alert(title: Text("common_warning"),
                         message: Text(alertMessage),
                         dismissButton: Alert.Button.default(Text("common_ok")))
        }
    }
    
	
	
	@Storage(type: .oldDeviceOldCardAlert, defaultValue: false)
    private var oldDeviceOldCardShown: Bool
    
	@Storage(type: .scannedCards, defaultValue: [])
    private var scannedCards: [String]
    
    func getAlert(_ alertType: AlertType, for card: Card) -> AlertBinder? {
        if canShow(alertType, card: card) {
            return AlertBinder(alert: alertType.alert)
        } else {
            return nil
        }
    }
    
    private func canShow(_ alertType: AlertType, card: Card) -> Bool {
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
        case .untrustedCard:
            guard let signedHashes = card.walletSignedHashes,
                let cid = card.cardId else {
                    return false
            }
            
            let scannedCards = self.scannedCards
            if scannedCards.contains(cid) {
                return false
            }
            
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
            if scannedCards.contains(cid) {
                return false
            }
            
            self.scannedCards = scannedCards + [cid]
            return true
        }
    }
}
