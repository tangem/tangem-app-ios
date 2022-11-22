//
//  WarningEventsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct WarningEventsFactory {
    func makeWarningEvents(for card: Card) -> [WarningEvent] {
        var warnings: [WarningEvent] = []

        if card.firmwareVersion.type != .sdk &&
            card.attestation.status == .failed {
            warnings.append(.failedToValidateCard)
        }

        for wallet in card.wallets {
            if let remainingSignatures = wallet.remainingSignatures,
               remainingSignatures <= 10 {
                warnings.append(.lowSignatures(count: remainingSignatures))
                break
            }
        }

        if card.firmwareVersion.type == .sdk && !DemoUtil().isDemoCard(cardId: card.cardId) {
            warnings.append(.devCard)
        }

        return warnings
    }
}
