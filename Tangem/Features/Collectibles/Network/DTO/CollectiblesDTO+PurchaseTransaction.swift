//
//  CollectiblesDTO+PurchaseTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct PurchaseTransaction: Decodable {
        let txID: String
        let status: String

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case status
        }
    }
}
