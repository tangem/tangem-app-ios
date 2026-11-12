//
//  OnboardVirtualAccountDeeplink.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

struct OnboardVirtualAccountDeeplink: HostNamedDeeplink, Equatable {
    static let host = "onboard-virtual-account"

    let deeplinkString: String

    var action: DeeplinkNavigationAction { .onboardVirtualAccount(self) }
}

// MARK: - Parsing

extension OnboardVirtualAccountDeeplink {
    private enum Keys {
        static let entry = "entry"
    }

    init(link: DeeplinkURL) throws {
        try link.query.requireAll(Keys.entry, Shared.id)

        deeplinkString = MarketingActivityUid.linkWithoutUid(link.absoluteString)
    }
}

// MARK: - Navigation

extension OnboardVirtualAccountDeeplink {
    var onboardingSource: TangemPayOnboardingSource {
        .deeplink(deeplinkString)
    }
}
