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
        case pseudoProvider(PseudoProvider)
        case standaloneCTA(StandaloneCTA)
    }

    struct PseudoProvider {
        let categoryLabel: String?
        let subtitle: String?
        let etaLabel: String?
        let partnerLabel: String?
        let buttonText: String
        let isGlowing: Bool
    }

    struct StandaloneCTA {
        let subtitle: String?
        let buttonText: String
        let isGlowing: Bool
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

    var isLinkedToProvider: Bool {
        if case .linkedToProvider = placement {
            return true
        }

        return false
    }

    var isCallToAction: Bool {
        switch placement {
        case .pseudoProvider, .standaloneCTA:
            true
        case .standalone, .linkedToProvider:
            false
        }
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
    let callToAction: [MarketingBanner]

    func removing(hiddenCampaignIds: Set<Int>) -> MarketingBanners {
        MarketingBanners(
            standalone: standalone.filter { !hiddenCampaignIds.contains($0.id) },
            linked: linked.filter { !hiddenCampaignIds.contains($0.id) },
            callToAction: callToAction.filter { !hiddenCampaignIds.contains($0.id) }
        )
    }
}
