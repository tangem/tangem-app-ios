//
//  TangemPayOnboardingLinkParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayOnboardingLinkParser: IncomingActionURLParser {
    static func matches(_ url: URL) -> Bool {
        // The query value alone is not a credential: without this host check any `https://evil.example/
        // ?deep_link_value=tpay_mobileonboard` (or a foreign-scheme URL) passed `CommonIncomingURLValidator`
        // and reached the whole parser chain. Only the OneLink domain and our own hosts may carry it.
        guard url.scheme == "https", let host = url.host?.lowercased(), Self.isAllowedHost(host) else {
            return false
        }

        let deeplinkValue = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == AppsFlyerDeepLinkKeys.value }?
            .value

        return deeplinkValue == AppsFlyerDeepLinkResolver.AppsflyerDeepLinkType.tangemPayMobileOnboarding
    }

    private static func isAllowedHost(_ host: String) -> Bool {
        host == IncomingActionConstants.appsFlyerOneLinkHost
            || IncomingActionConstants.supportedExternalLinkHosts.contains(host)
    }

    func parse(_ url: URL) -> IncomingAction? {
        guard Self.matches(url) else {
            return nil
        }

        let navigationAction = DeeplinkNavigationAction(
            destination: .onboardVisa,
            params: .empty,
            deeplinkString: url.absoluteString
        )
        return .navigation(navigationAction)
    }
}
