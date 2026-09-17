//
//  TangemPayCampaignLinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Matches the AppsFlyer link that names a Tangem Pay co-brand campaign. Like the onboarding OneLink it names
/// its destination by `deep_link_value` rather than by a host, so the domain it arrived from is what makes it
/// ours — anyone can write the value into a link of their own.
struct TangemPayCampaignLinkParser: IncomingActionURLParser {
    static func campaignKey(_ url: URL) -> String? {
        guard url.scheme == Constants.scheme,
              let host = url.host?.lowercased(),
              IncomingActionConstants.supportedExternalLinkHosts.contains(host)
        else {
            return nil
        }

        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
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

        return .navigation(PayCustomCardDeeplink(campaignKey: campaignKey).action)
    }
}

// MARK: - Constants

private extension TangemPayCampaignLinkParser {
    enum Constants {
        /// The app's own scheme is registered for anyone to call, so a link carrying the value has to arrive
        /// the way a real one does — on a domain of ours.
        static let scheme = "https"
    }
}
