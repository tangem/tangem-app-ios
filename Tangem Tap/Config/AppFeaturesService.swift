//
//  AppFeaturesService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AppFeaturesService {
	
	let configManager = try! FeaturesConfigManager()
	
	private var features = AppFeatures.all
	
	func setupFeatures(for card: Card) {
		features = getFeatures(for: card)
	}
	
    private func getFeatures(for card: Card) -> AppFeatures {
        if let issuerName = card.cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return .none
        }
        
		var features = AppFeatures.all
		
        if card.cardData?.blockchainName?.lowercased() == "btc" ||
			card.isTwinCard ||
			!configManager.features.isWalletPayIdEnabled {
			features.remove(.payIDReceive)
        }
		
		if !configManager.features.isSendingToPayIdEnabled {
			features.remove(.payIDSend)
		}
		
		if !configManager.features.isCreatingTwinCardsAllowed {
			features.remove(.twinCreation)
		}
		
		if !configManager.features.isTopUpEnabled {
			features.remove(.topup)
		}
        
        return features
    }
	
}

extension AppFeaturesService {
	var canSetAccessCode: Bool { features.contains(.pins) }
	
	var canSetPasscode: Bool { features.contains(.pins) }
	
	var linkedTerminal: Bool { features.contains(.linkedTerminal) }
	
	var canCreateTwin: Bool { features.contains(.twinCreation) }
	
	var isPayIdEnabled: Bool { canSendToPayId || canReceiveToPayId }
	
	var canSendToPayId: Bool { features.contains(.payIDSend) }
	
	var canReceiveToPayId: Bool { features.contains(.payIDReceive) }
	
	var canTopup: Bool { features.contains(.topup) }
}
