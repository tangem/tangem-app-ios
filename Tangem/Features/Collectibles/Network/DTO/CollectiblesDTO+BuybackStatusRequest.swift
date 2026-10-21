//
//  CollectiblesDTO+BuybackStatusRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct BuybackStatusRequest: Encodable {
        let buybackID: String

        private enum CodingKeys: String, CodingKey {
            case buybackID = "buybackId"
        }
    }
}
