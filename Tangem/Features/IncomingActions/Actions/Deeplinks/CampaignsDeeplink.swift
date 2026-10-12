//
//  CampaignsDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://campaigns[?campaignId]`
///
/// A missing campaign id falls back to the campaign-not-active sheet when the link is handled.
struct CampaignsDeeplink: HostNamedDeeplink, Equatable {
    static let host = "campaigns"

    let campaignId: String?

    var action: DeeplinkNavigationAction { .campaigns(self) }
}

// MARK: - Parsing

extension CampaignsDeeplink {
    private enum Keys {
        static let campaignId = "campaignId"
    }

    init(link: DeeplinkURL) throws {
        campaignId = try link.query.optional(Keys.campaignId)
    }
}
