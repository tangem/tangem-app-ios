//
//  EarnDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum EarnDTO {
    enum List {}
}

// MARK: - List

extension EarnDTO.List {
    struct Response: Decodable {
        let items: [Item]
        let meta: Meta
    }

    struct Meta: Decodable {
        let page: Int
        let limit: Int
    }

    struct Item: Decodable {
        let apy: String
        let networkId: String
        let rewardType: String
        let type: String
        let token: Token
    }

    struct Token: Decodable {
        let id: String
        let symbol: String
        let name: String
        let address: String?
    }
}
