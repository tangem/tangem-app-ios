//
//  TangemPayOnboardingLinkParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Matches the AppsFlyer OneLink that asks for Tangem Pay onboarding. It carries no parameters of its own,
/// so there is nothing to read but the `deep_link_value` — which anyone can write into a link, hence the
/// domain the OneLink is served from is checked first. It is the only one the app claims besides its own.
struct TangemPayOnboardingLinkParser: IncomingActionURLParser {
    static func matches(_ url: URL) -> Bool {
        guard url.scheme == Constants.scheme,
              let host = url.host?.lowercased(),
              IncomingActionConstants.supportedExternalLinkHosts.contains(host)
        else {
            return false
        }

        let deeplinkValue = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == AppsFlyerDeepLinkKeys.value }?
            .value

        return deeplinkValue == AppsFlyerDeepLinkResolver.AppsflyerDeepLinkType.tangemPayMobileOnboarding
    }

    func parse(_ url: URL) -> IncomingAction? {
        guard Self.matches(url) else {
            return nil
        }

        // The OneLink carries no parameters of its own, so onboarding has no deeplink to attribute itself to.
        return .navigation(.onboardVisa(OnboardVisaDeeplink(deeplinkString: nil)))
    }
}

// MARK: - Constants

private extension TangemPayOnboardingLinkParser {
    enum Constants {
        /// The app's own scheme is registered for anyone to call, so a link carrying the value has to arrive
        /// the way a real one does — on a domain of ours.
        static let scheme = "https"
    }
}
