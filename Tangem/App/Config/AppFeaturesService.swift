//
//  AppFeaturesService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AppFeaturesService {
	
    private let configProvider: FeaturesConfigProvider
    private var features: Set<AppFeature> = .all
    
    init(configProvider: FeaturesConfigProvider) {
        self.configProvider = configProvider
    }
    
    deinit {
        print("AppFeaturesService deinit")
    }
	
	func setupFeatures(for card: Card) {
		features = getFeatures(for: card)
	}
    
    private func getFeatures(for card: Card) -> Set<AppFeature> {
        if card.isStart2Coin {
            return .none
        }
        
		var features =  Set<AppFeature>.all
        let configFeatures = configProvider.features
		
        if card.isTwinCard ||
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
        
        if !configFeatures.isTopUpEnabled {
            features.remove(.topup)
        }
        
        features.remove(.pins)
        
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
	
	var canExchangeCrypto: Bool { features.contains(.topup) }
}
