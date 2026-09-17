//
//  EarnDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://earn[?earn_type&network_id]`
struct EarnDeeplink: HostNamedDeeplink, Equatable {
    static let host = "earn"

    let earnType: String?
    let networkId: String?

    var action: DeeplinkNavigationAction { .earn(self) }
}

// MARK: - Parsing

extension EarnDeeplink {
    private enum Keys {
        static let earnType = "earn_type"
    }

    init(link: DeeplinkURL) throws {
        earnType = try link.query.optional(Keys.earnType, lowercased: true)
        networkId = try link.query.optional(Shared.networkId, lowercased: true)
    }
}

// MARK: - Navigation

extension EarnDeeplink {
    var filterType: EarnFilterType? {
        earnType.flatMap(EarnFilterType.init(rawValue:))
    }
}
