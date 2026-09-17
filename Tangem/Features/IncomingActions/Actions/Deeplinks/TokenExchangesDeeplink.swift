//
//  TokenExchangesDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://token_exchanges?token_id`
struct TokenExchangesDeeplink: HostNamedDeeplink, Equatable {
    static let host = "token_exchanges"

    let tokenId: String

    var action: DeeplinkNavigationAction { .tokenExchanges(self) }
}

// MARK: - Parsing

extension TokenExchangesDeeplink {
    init(link: DeeplinkURL) throws {
        tokenId = try link.query.required(Shared.tokenId, lowercased: true)
    }
}
