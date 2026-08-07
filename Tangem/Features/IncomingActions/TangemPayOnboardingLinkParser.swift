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

        let navigationAction = DeeplinkNavigationAction(
            destination: .onboardVisa,
            params: .empty,
            deeplinkString: url.absoluteString
        )
        return .navigation(navigationAction)
    }
}
