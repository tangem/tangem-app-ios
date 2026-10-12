//
//  PayCustomCardDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The co-brand campaign an AppsFlyer link names by its `deep_link_value`. It answers to no host and no path:
/// `TangemPayCampaignLinkParser` is the only thing that builds it. The key it carries is written down as pending
/// on arrival — that stored key, not the link, is what survives until a screen can show it.
struct PayCustomCardDeeplink: Equatable {
    let campaignKey: String

    var action: DeeplinkNavigationAction { .payCustomCard(self) }
}
