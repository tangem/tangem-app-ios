//
//  CollectiblesDTO+BuybackTxSentRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct BuybackTxSentRequest: Encodable {
        let buybackID: String
        let txHash: String

        private enum CodingKeys: String, CodingKey {
            case buybackID = "buybackId"
            case txHash
        }
    }
}
