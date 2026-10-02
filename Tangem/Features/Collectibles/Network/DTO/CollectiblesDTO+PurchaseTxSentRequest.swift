//
//  CollectiblesDTO+PurchaseTxSentRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct PurchaseTxSentRequest: Encodable {
        let txID: String
        let txHash: String

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case txHash
        }
    }
}
