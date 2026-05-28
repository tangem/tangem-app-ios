//
//  PromotionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

typealias PromotionPlacement = PromotionsDTO.Placement

enum PromotionsDTO {}

extension PromotionsDTO {
    enum Placement: String, Codable, CaseIterable {
        case main
        case news = "shtorka"
        case tokenDetails = "token_details"
        case yield
    }
}

extension PromotionsDTO {
    enum Load {
        struct Request: Encodable {
            let walletId: String
            let placeholder: PromotionsDTO.Placement
            let language: String
        }

        struct Response: Decodable {
            let items: [Item]
        }

        struct Item: Decodable {
            let id: Int?
            let placeholder: PromotionsDTO.Placement?
            let priority: String?
            let title: String?
            let subtitle: String?
            let iconUrl: URL?
            let deeplink: URL?
            let buttonEnabled: Bool?
            let buttonText: String?
            let dismissable: Bool?
            let tokens: [TokenInfo]?
        }
    }
}

extension PromotionsDTO {
    enum Hide {
        struct Request: Encodable {
            let displayId: Int
            let walletId: String
            let status: Status

            enum CodingKeys: String, CodingKey {
                case walletId
                case status
            }
        }

        struct Response: Decodable {
            let displayId: Int
            let walletId: String
            let status: Status
        }

        enum Status: String, Codable {
            case active
            case dismissed
        }
    }
}
