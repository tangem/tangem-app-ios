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
        
        private var alertMessage: String {
            switch self {
            case .oldDeviceOldCard:
                return "alert_old_device_this_card".localized
            case .untrustedCard:
                return "alert_loaded_wallet_warning_card_signed_transactions".localized
            }
        }
        
        fileprivate var alert: Alert {
            return Alert(title: Text("common_warning".localized),
                         message: Text(alertMessage),
                         dismissButton: Alert.Button.default(Text("common_ok")))
        }
    }
    
    @Storage("tangem_tap_oldDeviceOldCard_shown", defaultValue: false)
    private var oldDeviceOldCardShown: Bool
    
    @Storage("tangem_tap_scanned_cards", defaultValue: [])
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
        }
    }
}
