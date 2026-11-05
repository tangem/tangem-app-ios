//
//  CollectiblesDTO+ActiveTransactions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct ActiveTransactions: Decodable {
        let activeTxs: [ActiveTransaction]
    }

    struct ActiveTransaction: Decodable {
        let txID: String
        let status: String
        let machine: ActiveTransactionMachine?
        let createdAt: Date

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case status
            case machine
            case createdAt
        }
    }

    struct ActiveTransactionMachine: Decodable {
        let externalID: String

        private enum CodingKeys: String, CodingKey {
            case externalID = "externalId"
        }
    }
}
