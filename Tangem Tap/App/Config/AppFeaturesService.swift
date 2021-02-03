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
	
    private let configProvider: FeaturesConfigProvider
	private var features = AppFeatures.all
    
    init(configProvider: FeaturesConfigProvider) {
        self.configProvider = configProvider
    }
	
	func setupFeatures(for card: Card) {
		features = getFeatures(for: card)
	}
	
    private func getFeatures(for card: Card) -> AppFeatures {
        if let issuerName = card.cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return .none
        }
        
		var features = AppFeatures.all
        let configFeatures = configProvider.features
		
        if card.cardData?.blockchainName?.lowercased() == "btc" ||
			card.isTwinCard ||
			!configFeatures.isWalletPayIdEnabled {
			features.remove(.payIDReceive)
        }
		
		if !configFeatures.isSendingToPayIdEnabled {
			features.remove(.payIDSend)
		}
		
		if !configFeatures.isCreatingTwinCardsAllowed {
			features.remove(.twinCreation)
		}
		
		if !configFeatures.isTopUpEnabled {
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
