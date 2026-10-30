//
//  MarketingActivityLinkRecorder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MarketingActivityLinkRecorder {
    @Injected(\.marketingActivityBindingService) private var bindingService: MarketingActivityBindingService

    func record(_ url: URL, for action: IncomingAction?) {
        guard !leavesUidToAppsFlyer(url),
              leadsToRouterDestination(url, action: action),
              let uid = MarketingActivityUid.read(from: url) else {
            return
        }

        bindingService.register(uid: uid)
    }
}

// MARK: - Private

private extension MarketingActivityLinkRecorder {
    func leavesUidToAppsFlyer(_ url: URL) -> Bool {
        guard case .path(let domain, _)? = DeeplinkURL(url: url.withLowercasedScheme())?.kind,
              IncomingActionConstants.attributionHosts.contains(domain) else {
            return false
        }

        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .contains { $0.name == AppsFlyerDeepLinkKeys.sub3 && $0.value?.isEmpty == false } ?? false
    }

    func leadsToRouterDestination(_ url: URL, action: IncomingAction?) -> Bool {
        if case .navigation = action {
            return true
        }

        return DeeplinkURL(url: url.withLowercasedScheme()).map(DeeplinkNavigationAction.namesDestination) ?? false
    }
}
