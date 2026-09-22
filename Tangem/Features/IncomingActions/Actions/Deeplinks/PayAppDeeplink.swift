//
//  PayAppDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// The same destination as Visa onboarding, asked for by its own name: `tangem://pay-app?id` and the page
/// `https://<our domain>/pay-app?id`.
struct PayAppDeeplink: HostNamedDeeplink, Equatable {
    static let host = "pay-app"

    let deeplinkString: String

    var action: DeeplinkNavigationAction { .payApp(self) }
}

// MARK: - Parsing

extension PayAppDeeplink {
    init(link: DeeplinkURL) throws {
        try link.query.requireAll(Shared.id)

        deeplinkString = link.absoluteString
    }
}

// MARK: - PathNamedDeeplink

extension PayAppDeeplink: PathNamedDeeplink {
    /// The page is named the same as the host, so both forms read alike.
    static let pathSegment = host

    static func action(from link: DeeplinkURL) -> DeeplinkNavigationAction? {
        guard case .path(_, let components) = link.kind, components.count == 1 else {
            return nil
        }

        return (try? PayAppDeeplink(link: link))?.action
    }
}

// MARK: - Navigation

extension PayAppDeeplink {
    var onboardingSource: TangemPayOnboardingSource {
        .deeplink(deeplinkString)
    }
}
