//
//  PromoCodeActivationDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum PromoCodeActivationDTO {}

extension PromoCodeActivationDTO {
    struct Request: Encodable {
        let walletAddress: String
        let promoCode: String
    }

    struct Response: Decodable {
        let promoCodeId: Int
        let status: Status

        enum Status: String, Decodable {
            case activated = "ACTIVATED"
            case unknown

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try container.decode(String.self)
                self = Status(rawValue: raw) ?? .unknown
            }
        }
    }
}
