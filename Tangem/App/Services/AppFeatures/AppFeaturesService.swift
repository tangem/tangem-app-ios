//
//  AppFeaturesService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class AppFeaturesService {
    @Injected(\.remoteConfigurationProvider) var configProvider: RemoteConfigurationProviding
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    var features: Set<AppFeature> {
        guard let card = cardsRepository.lastScanResult.card else {
            return .all
        }
        
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

        features.remove(.pins)
        
        return features
    }
    
    private var bag = Set<AnyCancellable>()
    
    init() {}
    
    deinit {
        print("AppFeaturesService deinit")
    }
}

extension AppFeaturesService: AppFeaturesProviding {    
	var canSetAccessCode: Bool { features.contains(.pins) }
	
	var canSetPasscode: Bool { features.contains(.pins) }
	
	var canCreateTwin: Bool { features.contains(.twinCreation) }
	
	var isPayIdEnabled: Bool { canSendToPayId || canReceiveToPayId }
	
	var canSendToPayId: Bool { features.contains(.payIDSend) }
	
	var canReceiveToPayId: Bool { features.contains(.payIDReceive) }
	
	var canExchangeCrypto: Bool { features.contains(.topup) }
}
