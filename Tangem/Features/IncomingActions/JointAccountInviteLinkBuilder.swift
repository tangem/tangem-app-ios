//
//  JointAccountInviteLinkBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Writes an invite out as the universal link `JointAccountInviteLinkParser` reads back. The app scheme carries the
/// same invite, but a link that leaves the device has to work on one without the app installed.
/// - Warning: The link is the invite, and the invite is the account's only access secret — see `StoredJointAccountInvite`.
struct JointAccountInviteLinkBuilder {
    func buildURL(invite: StoredJointAccountInvite) -> URL? {
        var components = URLComponents(string: IncomingActionConstants.tangemDomain)
        components?.path = IncomingActionConstants.jointAccountInvitePath

        guard var url = components?.url else {
            return nil
        }

        url.appendPathComponent(invite.id)

        return url
    }
}
