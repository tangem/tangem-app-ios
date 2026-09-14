//
//  JointAccountInviteLinkParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Parses an invite link in two formats: `https://tangem.com/joint-account/join/{inviteId}` and
/// `tangem://joint-account-invite?id={inviteId}`.
struct JointAccountInviteLinkParser: IncomingActionURLParser {
    private let deeplinkValidator: DeeplinkValidator

    init(deeplinkValidator: DeeplinkValidator = CommonDeepLinkValidator()) {
        self.deeplinkValidator = deeplinkValidator
    }

    func parse(_ url: URL) throws -> IncomingAction? {
        guard let inviteId = inviteId(from: url) else {
            return nil
        }

        let action = DeeplinkNavigationAction(
            destination: .jointAccountInvite,
            params: DeeplinkNavigationAction.Params(id: inviteId),
            deeplinkString: url.absoluteString
        )

        guard deeplinkValidator.hasMinimumDataForHandling(deeplink: action) else {
            return nil
        }

        return .navigation(action)
    }
}

// MARK: - Private

private extension JointAccountInviteLinkParser {
    func inviteId(from url: URL) -> String? {
        if isUniversalLink(url) {
            // pathComponents: ["/", "joint-account", "join", "{inviteId}"]
            let components = url.pathComponents

            return components.count >= 4 ? components[3].nilIfEmpty : nil
        }

        if isDeepLink(url) {
            return url.getKeyedQueryItems()[IncomingActionConstants.DeeplinkParams.id]?.nilIfEmpty
        }

        return nil
    }

    func isUniversalLink(_ url: URL) -> Bool {
        let prefix = IncomingActionConstants.tangemDomain + IncomingActionConstants.jointAccountInvitePath

        return url.absoluteString.starts(with: prefix)
    }

    func isDeepLink(_ url: URL) -> Bool {
        guard url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme) else {
            return false
        }

        return url.host?.lowercased() == IncomingActionConstants.DeeplinkDestination.jointAccountInvite.rawValue
    }
}

// MARK: - Helpers

private extension URL {
    func getKeyedQueryItems() -> [String: String] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.value?.isNotEmpty ?? false }
            .keyedFirst(by: \.name)
            .compactMapValues { $0.value?.removingPercentEncoding } ?? [:]
    }
}
