//
//  JointAccountsNetworkServiceMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct JointAccountsNetworkServiceMock: JointAccountsNetworkService {
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult {
        let config = blob.payload.config
        let creator = blob.payload.creator

        let account = StoredJointAccount(
            cryptoAccountId: UUID().uuidString,
            membersCount: config.membersCount,
            threshold: config.threshold,
            address: nil,
            status: .pending,
            members: [
                StoredJointAccount.Member(name: creator.name, address: creator.address, role: .creator),
            ]
        )

        let invites = (1 ..< config.membersCount).map { _ in JointAccountInvite(id: Self.makeInviteId()) }

        return JointAccountCreationResult(account: account, invites: invites)
    }

    private static func makeInviteId() -> String {
        (UUID().uuidString + UUID().uuidString).replacingOccurrences(of: "-", with: "")
    }
}
