//
//  TangemPayCampaignLinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayCampaignLinkParser: IncomingActionURLParser {
    static func campaignKey(_ url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == AppsFlyerDeepLinkKeys.value }?
            .value
            .flatMap(TangemPayCampaignService.campaignKey(fromDeepLinkValue:))
    }

    static func matches(_ url: URL) -> Bool {
        campaignKey(url) != nil
    }

    func parse(_ url: URL) -> IncomingAction? {
        guard let campaignKey = Self.campaignKey(url) else {
            return nil
        }

        // The AppsFlyer SDK resolves the same link through its own callback, so both paths store the key
        // and whichever arrives second is a no-op.
        TangemPayCampaignService().markPending(campaignKey: campaignKey)

        var params = DeeplinkNavigationAction.Params.empty
        params.campaignId = campaignKey

        let navigationAction = DeeplinkNavigationAction(
            destination: .payCustomCard,
            params: params,
            deeplinkString: url.absoluteString
        )
        return .navigation(navigationAction)
    }
}
