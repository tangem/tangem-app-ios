//
//  CommonJointAccountsNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// - Note: Nothing here is retried. Creating and joining are spent once by contract, so a repeat answers with a
/// conflict rather than the same result; activating is the exception and repeats happily, but only its caller knows
/// whether a repeat is what it wants. The two reads are cheap enough to leave to whoever asked.
final class CommonJointAccountsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId
    private let mapper: JointAccountsNetworkMapper

    init(userWalletId: UserWalletId, mapper: JointAccountsNetworkMapper = JointAccountsNetworkMapper()) {
        self.userWalletId = userWalletId
        self.mapper = mapper
    }
}

// MARK: - JointAccountsNetworkService

extension CommonJointAccountsNetworkService: JointAccountsNetworkService {
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult {
        let response = try await tangemApiService.createJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )

        return mapper.mapToCreationResult(from: response)
    }

    func getJointAccounts() async throws -> [StoredJointAccount] {
        let response = try await tangemApiService.getJointAccounts(walletId: userWalletId.stringValue)

        return mapper.mapToJointAccounts(from: response)
    }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        let response = try await tangemApiService.getJointAccountInvite(
            walletId: userWalletId.stringValue,
            inviteId: inviteId
        )

        return mapper.mapToInvitePreview(from: response)
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> StoredJointAccount {
        let response = try await tangemApiService.joinJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )

        return mapper.mapToJointAccount(from: response)
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> StoredJointAccount {
        let response = try await tangemApiService.activateJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )

        return mapper.mapToJointAccount(from: response)
    }
}
