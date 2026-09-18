//
//  TangemPayCampaignLinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Matches the AppsFlyer link that names a Tangem Pay co-brand campaign. Like the onboarding OneLink it names
/// its destination by `deep_link_value` rather than by a host, so the domain it arrived from is what makes it
/// ours — anyone can write the value into a link of their own.
struct TangemPayCampaignLinkParser: IncomingActionURLParser {
    static func campaignKey(_ url: URL) -> String? {
        guard isFromTrustedSource(url) else {
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

    private static func isFromTrustedSource(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        if url.scheme == Constants.webScheme, IncomingActionConstants.supportedExternalLinkHosts.contains(host) {
            return true
        }

        if AppEnvironment.current.isInternalOrDebug,
           url.absoluteString.starts(with: IncomingActionConstants.appScheme),
           host == Constants.appSchemeCampaignHost {
            return true
        }

        return false
    }
}

// MARK: - Constants

private extension TangemPayCampaignLinkParser {
    enum Constants {
        static let webScheme = "https"
        static let appSchemeCampaignHost = "marketing"
    }
}
