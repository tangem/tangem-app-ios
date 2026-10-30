//
//  JointAccountInviteLinkBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Writes an invite out as the universal link `JointAccountInviteDeeplink` reads back. The app scheme carries the
/// same invite, but a link that leaves the device has to work on one without the app installed.
/// - Warning: The link is the invite, and the invite is the account's only access secret.
struct JointAccountInviteLinkBuilder {
    func buildURL(inviteId: String) throws(Error) -> URL {
        var components = URLComponents(string: IncomingActionConstants.tangemDomain)
        components?.path = JointAccountInviteDeeplink.path(inviteId: inviteId)

        guard let url = components?.url else {
            throw .malformedLink
        }

        return url
    }
}

// MARK: - Error

extension JointAccountInviteLinkBuilder {
    enum Error: Swift.Error {
        case malformedLink
    }
}
