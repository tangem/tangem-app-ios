//
//  RemoteCollectiblesBuybackStatusProvider+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension RemoteCollectiblesBuybackStatusProvider {
    enum Mapper {
        static func mapToStatus(_ response: CollectiblesDTO.BuybackStatusResponse) -> CollectiblesBuybackStatus {
            switch response.status {
            case "created": .created
            case "waiting-tx-hash": .waitingTxHash
            case "buyback-tx-sent": .buybackTxSent
            case "confirming": .confirming
            case "confirmed": .confirmed
            case "expired": .expired
            default: .unknown(response.status)
            }
        }
    }
}
