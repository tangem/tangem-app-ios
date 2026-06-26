//
//  MarketingCampaignsDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MarketingCampaignsDTO {
    enum Request: Equatable {
        case swap(Swap)

        struct Swap: Equatable {
            let fromNetwork: String
            let fromContractAddress: String?
            let toNetwork: String
            let toContractAddress: String?
            let language: String?
        }
    }

    struct Response: Decodable {
        let campaigns: [Campaign]
    }

    struct Campaign: Decodable {
        let id: Int
        let type: String
        let priority: Int
        let minAmount: Decimal?
        let maxAmount: Decimal?
        let providerIds: [String]?
        let banner: Banner
    }

    struct Banner: Decodable {
        let uiType: UIType
        let text: String?
        let icon: URL?
        let bgColor: String?
        let deeplink: URL?
        let dismissible: Bool

        enum UIType: Decodable {
            case standalone
            case linkedToProvider
            case unknown(String)

            init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)

                switch raw {
                case "standalone":
                    self = .standalone
                case "linked_to_provider":
                    self = .linkedToProvider
                default:
                    self = .unknown(raw)
                }
            }
        }
    }
}

extension MarketingCampaignsDTO.Request {
    var parameters: [String: Any] {
        switch self {
        case .swap(let swap):
            var parameters: [String: Any] = [
                "type": "swap",
                "fromNetwork": swap.fromNetwork,
                "toNetwork": swap.toNetwork,
            ]
            parameters["fromContractAddress"] = swap.fromContractAddress
            parameters["toContractAddress"] = swap.toContractAddress
            parameters["language"] = swap.language
            return parameters
        }
    }
}
