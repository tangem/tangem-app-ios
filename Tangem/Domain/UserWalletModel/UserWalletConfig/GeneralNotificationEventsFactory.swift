//
//  GeneralNotificationEventsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import TangemHotSdk

struct GeneralNotificationEventsFactory {
    func makeNotifications(for card: CardDTO) -> [GeneralNotificationEvent] {
        var notifications: [GeneralNotificationEvent] = []

        if card.firmwareVersion.type != .sdk,
           card.attestation.status == .failed {
            notifications.append(.failedToVerifyCard)
        }

        if AppEnvironment.current.isTestnet {
            notifications.append(.testnetCard)
        } else if card.firmwareVersion.type == .sdk, !DemoUtil().isDemoCard(cardId: card.cardId) {
            notifications.append(.devCard)
        }

        return notifications
    }

    func makeNotifications(for hotWallet: HotWallet) -> [GeneralNotificationEvent] {
        []
    }
}
