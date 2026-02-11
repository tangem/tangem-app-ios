//
//  GaslessTransactionsDTO+FeeRecipientResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Response {
    struct FeeRecipientResponse: Decodable {
        let feeRecipientAddress: String

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case feeRecipientAddress
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            feeRecipientAddress = try result.decode(String.self, forKey: .feeRecipientAddress)
        }
    }
}
