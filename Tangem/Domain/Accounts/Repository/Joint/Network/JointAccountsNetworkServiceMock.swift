//
//  JointAccountsNetworkServiceMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountsNetworkServiceMock: JointAccountsNetworkService {
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult {
        throw "Not implemented"
    }

    func getJointAccounts() async throws -> [StoredJointAccount] {
        throw "Not implemented"
    }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        throw "Not implemented"
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> StoredJointAccount {
        throw "Not implemented"
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> StoredJointAccount {
        throw "Not implemented"
    }
}
