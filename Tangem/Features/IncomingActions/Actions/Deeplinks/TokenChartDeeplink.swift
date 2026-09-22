//
//  TokenChartDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://token_chart?token_id`
struct TokenChartDeeplink: HostNamedDeeplink, Equatable {
    static let host = "token_chart"

    let tokenId: String

    var action: DeeplinkNavigationAction { .tokenChart(self) }
}

// MARK: - Parsing

extension TokenChartDeeplink {
    init(link: DeeplinkURL) throws {
        tokenId = try link.query.required(Shared.tokenId, lowercased: true)
    }
}
