//
//  CollectiblesDTO+PurchaseTransactionRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct PurchaseTransactionRequest: Encodable {
        let txID: String
        var includeNftWon: Bool?

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case includeNftWon
        }
    }
}
