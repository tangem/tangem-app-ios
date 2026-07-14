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
        case onramp(Onramp)
        case staking(language: String?)
        case yield(language: String?)
        case tokenDetails(language: String?)
        case marketsToken(language: String?)

        struct Swap: Equatable {
            let fromNetwork: String
            let fromContractAddress: String?
            let toNetwork: String
            let toContractAddress: String?
            let language: String?
        }

        struct Onramp: Equatable {
            let toNetwork: String
            let toContractAddress: String?
            let fiatCurrency: String?
            let language: String?
        }
    }

    struct Response: Decodable {
        let campaigns: [Campaign]
    }

    struct Campaign: Codable {
        let id: Int
        let type: String
        let priority: Int
        let minAmount: Decimal?
        let maxAmount: Decimal?
        let providerIds: [String]?
        let tokens: [Token]?
        let banner: Banner

        struct Token: Codable {
            let networkId: String?
            let contractAddress: String?
            let id: String?
        }
    }

    struct Banner: Codable {
        let uiType: UIType
        let text: String?
        let icon: URL?
        let bgColor: String?
        let deeplink: URL?
        let dismissible: Bool

        enum UIType: Codable {
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

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()

                let raw: String = switch self {
                case .standalone:
                    "standalone"
                case .linkedToProvider:
                    "linked_to_provider"
                case .unknown(let raw):
                    raw
                }

                try container.encode(raw)
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

        case .onramp(let onramp):
            var parameters: [String: Any] = [
                "type": "onramp",
                "toNetwork": onramp.toNetwork,
            ]
            parameters["toContractAddress"] = onramp.toContractAddress
            parameters["fromFiat"] = onramp.fiatCurrency
            parameters["language"] = onramp.language
            return parameters

        case .staking(let language):
            var parameters: [String: Any] = ["type": "staking"]
            parameters["language"] = language
            return parameters

        case .yield(let language):
            var parameters: [String: Any] = ["type": "yield"]
            parameters["language"] = language
            return parameters

        case .tokenDetails(let language):
            var parameters: [String: Any] = ["type": "token_details"]
            parameters["language"] = language
            return parameters

        case .marketsToken(let language):
            var parameters: [String: Any] = ["type": "markets_token"]
            parameters["language"] = language
            return parameters
        }
    }
}
