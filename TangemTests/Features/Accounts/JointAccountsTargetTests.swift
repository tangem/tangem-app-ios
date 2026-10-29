//
//  JointAccountsTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("Joint accounts targets")
struct JointAccountsTargetTests {
    @Test("An invite is issued with a POST to the invites of the wallet's joint accounts")
    func issueInviteTarget() {
        let target = TangemApiTarget(
            type: .issueJointAccountInvite(walletId: "wallet", body: JointAccountsDTO.Request.IssueInvite(cryptoAccountId: "account", slot: 2))
        )

        #expect(target.path == "/wallets/wallet/joint-accounts/invites")
        #expect(target.method == .post)
    }

    @Test("An account is confirmed with a POST to confirm, next to the activation it replaces")
    func confirmTarget() {
        let payload = JointAccountConfirmationPayload(
            name: "Family",
            icon: "Family",
            iconColor: "Azure",
            membersCount: 2,
            threshold: 2,
            safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        )
        let target = TangemApiTarget(
            type: .confirmJointAccount(walletId: "wallet", body: JointAccountsDTO.Request.Confirm(payload: payload, signature: "0x00"))
        )

        #expect(target.path == "/wallets/wallet/joint-accounts/confirm")
        #expect(target.method == .post)
    }
}
