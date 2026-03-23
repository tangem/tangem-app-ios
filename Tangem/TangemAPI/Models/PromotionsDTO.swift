//
//  PromotionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

typealias Promotion = PromotionsDTO.Load.Item
typealias PromotionPlacement = PromotionsDTO.Placement

enum PromotionsDTO {}

extension PromotionsDTO {
    enum Placement: String, Codable {
        case main
        case news = "shtorka"
    }
}

extension PromotionsDTO {
    enum Load {
        struct Request: Encodable {
            let walletId: String
            let placeholder: PromotionsDTO.Placement
            let lang: String
        }

        struct Response: Decodable {
            let items: [Item]
        }

        struct Item: Decodable {
            let id: Int
            let placeholder: PromotionsDTO.Placement
            let priority: String
            let title: String
            let subtitle: String
            let iconUrl: URL
            let deeplink: URL?
            let buttonEnabled: Bool
            let buttonText: String?
            let dismissable: Bool
        }
    }
}

extension PromotionsDTO {
    enum Hide {
        struct Request: Encodable {
            let displayId: Int
            let walletId: String
            let isDismissed: Bool

            enum CodingKeys: String, CodingKey {
                case walletId
                case isDismissed
            }
        }

        struct Response: Decodable {
            let displayId: Int
            let walletId: String
            let isDismissed: Bool
        }
    }
}
