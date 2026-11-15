//
//  PolymarketDTO+CLOB.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct CredentialsResponse: Decodable {
        let apiKey: String
        let secret: String
        let passphrase: String
    }

    struct SessionSignersResponse: Decodable {
        let signers: [SessionSigner]?
    }

    struct SessionSigner: Decodable {
        let address: String
        let scopes: [String]?
        let validUntil: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            address = try container.decode(String.self, forKey: .address)
            scopes = try container.decodeIfPresent([String].self, forKey: .scopes)

            do {
                validUntil = try container.decodeIfPresent(Int.self, forKey: .validUntil)
            } catch DecodingError.typeMismatch {
                let string = try container.decode(String.self, forKey: .validUntil)

                guard let seconds = Int(string) else {
                    throw DecodingError.dataCorruptedError(forKey: .validUntil, in: container, debugDescription: "Expected Unix seconds")
                }

                validUntil = seconds
            }
        }

        private enum CodingKeys: String, CodingKey {
            case address
            case scopes
            case validUntil = "valid_until"
        }
    }

    struct BalanceAllowanceResponse: Decodable {
        let balance: String
        let allowance: String?
    }
}
