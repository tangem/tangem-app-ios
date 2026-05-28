//
//  Promotion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct Promotion: Hashable {
    let id: Int
    let placeholder: PromotionPlacement
    let priority: String?
    let title: String
    let subtitle: String
    let iconUrl: URL?
    let deeplink: URL?
    let buttonEnabled: Bool
    let buttonText: String?
    let dismissable: Bool
    let tokens: [TokenInfo]?
}

// MARK: - Token Info

extension Promotion {
    struct TokenInfo: Hashable {
        let networkId: String
        let token: Token
    }

    struct Token: Hashable {
        let id: String
        let symbol: String
        let name: String
        let address: String
        let decimalCount: Int
    }
}

// MARK: - Token Matching

extension Promotion {
    func matches(networkId: String, tokenAddress: String) -> Bool {
        tokens?.contains { $0.networkId == networkId && $0.token.address == tokenAddress } ?? false
    }
}
