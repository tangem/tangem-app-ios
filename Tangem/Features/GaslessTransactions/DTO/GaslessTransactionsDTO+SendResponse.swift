//
//  GaslessTransactionsDTO+SendResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension GaslessTransactionsDTO.Response {
    struct SendResponse: Decodable {
        let txHash: String

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case txHash
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            txHash = try result.decode(String.self, forKey: .txHash)
        }
    }
}
