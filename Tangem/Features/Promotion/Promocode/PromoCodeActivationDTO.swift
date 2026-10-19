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
        let address: String
        let promoCode: String
        let walletId: String
        let paymentNetwork: String?
        let paymentCurrency: String?
    }

    struct Response: Decodable {
        let promoCodeId: String
        let status: Status
        let promoProgram: PromoProgram?

        struct PromoProgram: Decodable {
            let id: String
        }

        enum Status: String, Decodable {
            case activated
            case unknown

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try container.decode(String.self)
                self = Status(rawValue: raw) ?? .unknown
            }
        }
    }
}
