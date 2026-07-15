//
//  MarketingBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MarketingBanner {
    let id: Int
    let text: String
    let iconURL: URL?
    // [REDACTED_TODO_COMMENT]
    let backgroundColorHex: String?
    let placement: Placement
    let action: Action?
    let isDismissible: Bool
}

extension MarketingBanner {
    enum Placement {
        case standalone
        case linkedToProvider(providerIds: [String])
    }

    enum Action {
        case deeplink(URL)
    }

    var isStandalone: Bool {
        if case .standalone = placement {
            return true
        }

        return false
    }

    func matchesProvider(id: String) -> Bool {
        if case .linkedToProvider(let providerIds) = placement {
            return providerIds.contains(id)
        }

        return false
    }
}

struct MarketingBanners {
    let standalone: [MarketingBanner]
    let linked: [MarketingBanner]

    static let empty = MarketingBanners(standalone: [], linked: [])
}
