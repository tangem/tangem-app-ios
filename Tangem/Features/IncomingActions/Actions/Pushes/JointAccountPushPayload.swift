//
//  JointAccountPushPayload.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountPushPayload {
    let entry: JointAccountDeeplink.Entry
    let userWalletId: String
    let accountId: String

    var action: DeeplinkNavigationAction {
        .jointAccount(JointAccountDeeplink(entry: entry, userWalletId: userWalletId, accountId: accountId))
    }

    init?(userInfo: [AnyHashable: Any]) {
        let params = IncomingActionConstants.DeeplinkParams.self

        guard
            let userWalletId = userInfo.nonNullString(params.userWalletId),
            let accountId = userInfo.nonNullString(params.accountId),
            let type = userInfo.nonNullString(TokenDeeplink.Keys.type).flatMap(RawType.init(rawValue:))
        else {
            return nil
        }

        entry = type.entry
        self.userWalletId = userWalletId
        self.accountId = accountId.lowercased()
    }
}

private extension JointAccountPushPayload {
    enum RawType: String {
        case jointMembers = "joint_members"
        case jointOverview = "joint_overview"

        var entry: JointAccountDeeplink.Entry {
            switch self {
            case .jointMembers: .members
            case .jointOverview: .overview
            }
        }
    }
}
