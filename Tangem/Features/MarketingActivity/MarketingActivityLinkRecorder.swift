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
        guard leadsToRouterDestination(url, action: action), let uid = MarketingActivityUid.read(from: url) else {
            return
        }

        bindingService.register(uid: uid)
    }
}

// MARK: - Private

private extension MarketingActivityLinkRecorder {
    func leadsToRouterDestination(_ url: URL, action: IncomingAction?) -> Bool {
        if case .navigation = action {
            return true
        }

        return DeeplinkURL(url: url.withLowercasedScheme()).map(DeeplinkNavigationAction.namesDestination) ?? false
    }
}
