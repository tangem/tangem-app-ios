//
//  JointAccountsNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The joint accounts of a single wallet, as the backend keeps them.
/// - Note: Creating one is the endpoint's business alone: it mints the account's identifier and adds the entry the
/// creator's own account list holds for it.
protocol JointAccountsNetworkService {
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult
}

struct JointAccountCreationResult {
    let account: StoredJointAccount
    /// One per slot the creator left free, which is the only time they are ever handed out — see `JointAccountInvite`.
    let invites: [JointAccountInvite]
}
