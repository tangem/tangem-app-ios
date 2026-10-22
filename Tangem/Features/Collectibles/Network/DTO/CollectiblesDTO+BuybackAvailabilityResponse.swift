//
//  CollectiblesDTO+BuybackAvailabilityResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct BuybackAvailabilityResponse: Decodable {
        let buybackAvailable: Bool
        let buybackAmountInCents: Decimal?
        let buybackExpiresAt: Date?

        private enum CodingKeys: String, CodingKey {
            case buybackAvailable
            case buybackAmountInCents = "buybackAmount"
            case buybackExpiresAt
        }
    }
}
