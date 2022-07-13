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
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    var features: Set<AppFeature> {
        guard let card = cardsRepository.lastScanResult.card else {
            return .all
        }

        if card.isStart2Coin {
            return .none
        }

        var features =  Set<AppFeature>.all
        features.remove(.pins)
        return features
    }

    init() {}

    deinit {
        print("AppFeaturesService deinit")
    }
}

extension AppFeaturesService: AppFeaturesProviding {
    var canSetAccessCode: Bool { features.contains(.pins) }

    var canSetPasscode: Bool { features.contains(.pins) }

    var canCreateTwin: Bool { features.contains(.twinCreation) }

    var isPayIdEnabled: Bool { canSendToPayId }

    var canSendToPayId: Bool { features.contains(.payIDSend) }

    var canExchangeCrypto: Bool { features.contains(.topup) }
}
