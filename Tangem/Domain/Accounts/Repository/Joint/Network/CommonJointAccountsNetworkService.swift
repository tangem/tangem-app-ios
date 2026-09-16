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

        return try mapper.mapToCreationResult(from: response)
    }

    func getJointAccounts() async throws -> [RemoteJointAccount] {
        let response = try await tangemApiService.getJointAccounts(walletId: userWalletId.stringValue)

        return try mapper.mapToJointAccounts(from: response)
    }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        let response = try await tangemApiService.getJointAccountInvite(
            walletId: userWalletId.stringValue,
            inviteId: inviteId
        )

        return mapper.mapToInvitePreview(from: response)
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> RemoteJointAccount {
        let response = try await tangemApiService.joinJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )

        return try mapper.mapToJointAccount(from: response)
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount {
        let response = try await tangemApiService.activateJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )

        return try mapper.mapToJointAccount(from: response)
    }

    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation {
        let response = try await tangemApiService.createJointAccountOperation(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: request)
        )

        return try mapper.mapToOperation(from: response)
    }

    func signOperation(id: String, signature: Data) async throws -> JointAccountOperation {
        let response = try await tangemApiService.signJointAccountOperation(
            walletId: userWalletId.stringValue,
            operationId: id,
            body: mapper.mapToRequest(from: signature)
        )

        return try mapper.mapToOperation(from: response)
    }

    func rejectOperation(id: String, blob: JointAccountOperationRejectionBlob) async throws -> JointAccountOperation? {
        let response = try await tangemApiService.rejectJointAccountOperation(
            walletId: userWalletId.stringValue,
            operationId: id,
            body: mapper.mapToRequest(from: blob)
        )

        return try response.map(mapper.mapToOperation(from:))
    }
}
