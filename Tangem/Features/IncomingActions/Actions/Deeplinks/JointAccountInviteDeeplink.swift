//
//  JointAccountInviteDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// An invite to a joint account, asked for as `tangem://joint-account-invite?id` or as the page
/// `https://tangem.com/joint-account/join/{inviteId}`. The invite id is the whole link — without it there is
/// nothing to look up.
struct JointAccountInviteDeeplink: HostNamedDeeplink, Equatable {
    static let host = "joint-account-invite"

    let inviteId: String

    var action: DeeplinkNavigationAction { .jointAccountInvite(self) }
}

// MARK: - Parsing

extension JointAccountInviteDeeplink {
    init(link: DeeplinkURL) throws {
        inviteId = try link.query.required(Shared.id)
    }
}

// MARK: - PathNamedDeeplink

extension JointAccountInviteDeeplink: PathNamedDeeplink {
    static let pathSegment = "joint-account"

    private static let joinComponent = "join"

    /// The path an invite is written into, read back by `action(from:)` below.
    static func path(inviteId: String) -> String {
        "/\(pathSegment)/\(joinComponent)/\(inviteId)"
    }

    static func action(from link: DeeplinkURL) -> DeeplinkNavigationAction? {
        // Invites live on the main domain only, so a page of the same shape elsewhere stays a page.
        guard
            case .path(IncomingActionConstants.tangemHost, let components) = link.kind,
            components.count >= 3,
            components[1].lowercased() == joinComponent
        else {
            return nil
        }

        guard let inviteId = DeeplinkRules.identifier(components[2]) else {
            return nil
        }

        return JointAccountInviteDeeplink(inviteId: inviteId).action
    }
}
