//
//  PromoCampaignContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PromoCampaignContent: Equatable {
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let blocks: [Block]
    let learnMoreLink: Link?
    let termsLink: Link?
    let actionButtonTitle: String
}

extension PromoCampaignContent {
    struct Link: Equatable {
        let title: String
        let url: URL
    }

    enum Block: Equatable {
        case text(title: String?, text: String, link: Link?)
        case highlight(title: String?, text: String)
        case items(title: String?, items: [Item])
        case table(Table)
    }

    struct Item: Equatable {
        let label: String
        let value: String
    }

    struct Table: Equatable {
        let title: String?
        let headers: [String]
        let rows: [[String]]
    }
}
