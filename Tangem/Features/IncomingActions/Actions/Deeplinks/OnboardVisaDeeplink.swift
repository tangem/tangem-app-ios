//
//  OnboardVisaDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://onboard-visa?entry&id`
///
/// The link itself is carried along because onboarding reports where it came from. `nil` for the OneLink
/// that carries no parameters of its own.
struct OnboardVisaDeeplink: HostNamedDeeplink, Equatable {
    static let host = "onboard-visa"

    let deeplinkString: String?

    var action: DeeplinkNavigationAction { .onboardVisa(self) }
}

// MARK: - Parsing

extension OnboardVisaDeeplink {
    private enum Keys {
        static let entry = "entry"
    }

    init(link: DeeplinkURL) throws {
        try link.query.requireAll(Keys.entry, Shared.id)

        deeplinkString = link.absoluteString
    }
}

// MARK: - Navigation

extension OnboardVisaDeeplink {
    /// An offer reached by a link is not the same offer as one reached by a tap: the onboarding validates the
    /// link before showing it.
    var onboardingSource: TangemPayOnboardingSource {
        deeplinkString.map { .deeplink($0) } ?? .other
    }
}
