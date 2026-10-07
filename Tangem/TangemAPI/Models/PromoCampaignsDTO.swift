//
//  PromoCampaignsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PromoCampaignsDTO {}

// MARK: - Request

extension PromoCampaignsDTO {
    struct Request: Encodable {
        let walletId: String
        let walletType: WalletType
        let batchId: String?
        let language: String
    }
}

extension PromoCampaignsDTO.Request {
    enum WalletType: String, Encodable {
        case mobile
        case card
    }

    init(wallet: PromoCampaignWallet, language: String) {
        switch wallet.identity {
        case .card(let batchId):
            self.init(walletId: wallet.userWalletId.stringValue, walletType: .card, batchId: batchId, language: language)
        case .mobile:
            self.init(walletId: wallet.userWalletId.stringValue, walletType: .mobile, batchId: nil, language: language)
        }
    }
}

// MARK: - Response

extension PromoCampaignsDTO {
    struct Response: Decodable {
        @LossyArray private(set) var promotions: [Promotion]
    }

    struct Promotion: Decodable {
        let id: Int
        let name: String
        let alreadyEnrolled: Bool
        let content: Content
        let properties: Properties
    }
}

// MARK: - Properties

extension PromoCampaignsDTO {
    struct Properties: Decodable {
        let payoutNeeded: Bool
        let payoutTokens: [PayoutToken]?
        let matchMode: MatchMode
    }

    struct PayoutToken: Decodable {
        let tokenAddress: String
        let networkId: String
        let tokenSymbol: String
        let tokenName: String
        let tokenId: String?
        let decimals: Int?
    }

    enum MatchMode: String, Decodable {
        case strict
        case linkedWallet = "linked_wallet"
    }
}

// MARK: - Content

extension PromoCampaignsDTO {
    struct Content: Decodable {
        let campaignName: String
        let campaignDescription: String?
        @LossyArray private(set) var publicDescription: [ContentBlock]
        let publicImage: URL?
        let learnMoreLink: Link?
        let tncLink: Link?
        let actionButtonName: String
    }

    struct Link: Decodable {
        let text: String
        let url: URL
    }
}

// MARK: - Content blocks

extension PromoCampaignsDTO {
    enum ContentBlock: Decodable {
        case text(TextBlock)
        case table(TableBlock)
        case highlight(HighlightBlock)
        case block(ItemsBlock)

        private enum CodingKeys: String, CodingKey {
            case type
        }

        private enum Kind: String, Decodable {
            case text
            case table
            case highlight
            case block
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            switch try container.decode(Kind.self, forKey: .type) {
            case .text:
                self = .text(try TextBlock(from: decoder))
            case .table:
                self = .table(try TableBlock(from: decoder))
            case .highlight:
                self = .highlight(try HighlightBlock(from: decoder))
            case .block:
                self = .block(try ItemsBlock(from: decoder))
            }
        }
    }

    struct TextBlock: Decodable {
        let title: String?
        let text: String
        let link: Link?

        private enum CodingKeys: String, CodingKey {
            case title
            case text
            case link
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            text = try container.decode(String.self, forKey: .text)
            link = try? container.decodeIfPresent(Link.self, forKey: .link)
        }
    }

    struct HighlightBlock: Decodable {
        let title: String?
        let text: String
    }

    struct ItemsBlock: Decodable {
        let title: String?
        let items: [Item]
    }

    struct TableBlock: Decodable {
        let title: String?
        let headers: [String]?
        let columnTypes: [ValueType]?
        let rows: [[Cell]]

        struct Cell: Decodable {
            let text: String?
            let value: Decimal?
            let currency: String?
        }
    }

    struct Item: Decodable {
        let label: String
        let value: Value
        let valueType: ValueType
        let currency: String?
    }

    enum ValueType: String, Decodable {
        case text
        case number
        case percent
        case money
    }

    enum Value: Decodable {
        case number(Decimal)
        case text(String)

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let number = try? container.decode(Decimal.self) {
                self = .number(number)
            } else {
                self = .text(try container.decode(String.self))
            }
        }
    }
}
