//
//  EvmTransactionBulkScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum EvmTransactionBulkScan {
        struct Request: Encodable {
            let chain: BlockaidDTO.Chain
            let options: [Option] = [.gasEstimation]
            let metadata: Metadata = .init(domain: "https://tangem.com")
            let data: [Data]
            let aggregated: Bool

            struct Metadata: Encodable {
                let domain: String
            }

            struct Data: Encodable {
                let from: String
                let to: String
                let value: String
                let data: String
            }

            struct TransactionParams: Codable {
                let from: String
                let to: String
                let data: String
                let value: String
            }
        }

        typealias Response = [ResponseElement]

        struct ResponseElement: Decodable {
            let gasEstimation: GasEstimation

            struct GasEstimation: Decodable {
                let status: String
                let used: String
                let estimate: String
            }
        }
    }
}
