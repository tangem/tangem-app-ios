//
//  CommonJointAccountsNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// - Note: Nothing here is retried. Creating and joining are spent once by contract, so a repeat answers with a
/// conflict rather than the same result; activating is the exception and repeats happily, but only its caller knows
/// whether a repeat is what it wants. The two reads are cheap enough to leave to whoever asked.
final class CommonJointAccountsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.eTagStorage) private var eTagStorage: ETagStorage

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
        invalidateJointAccountsETag()

        return try mapper.mapToCreationResult(from: response)
    }

    func getJointAccounts(knownETag: String?) async throws -> JointAccountsRemoteState {
        guard let (eTag, response) = try await tangemApiService.getJointAccounts(walletId: userWalletId.stringValue, knownETag: knownETag) else {
            return .notModified
        }

        return try .changed(mapper.mapToJointAccounts(from: response), eTag: eTag)
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
        invalidateJointAccountsETag()

        return try mapper.mapToJointAccount(from: response)
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount {
        let response = try await tangemApiService.activateJointAccount(
            walletId: userWalletId.stringValue,
            body: mapper.mapToRequest(from: blob)
        )
        invalidateJointAccountsETag()

        return try mapper.mapToJointAccount(from: response)
    }

    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation {
        do {
            let response = try await tangemApiService.createJointAccountOperation(
                walletId: userWalletId.stringValue,
                body: mapper.mapToRequest(from: request)
            )
            invalidateJointAccountsETag()

            return try mapper.mapToOperation(from: response)
        } catch let error as TangemAPIError where error.code == .conflict {
            throw JointOperationError.networkBusy
        } catch let error as TangemAPIError {
            guard let refusal = mapper.mapToRefusal(from: error) else {
                throw error
            }

            throw JointOperationError.refused(refusal)
        }
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data) async throws -> JointAccountOperation {
        let response = try await tangemApiService.signJointAccountOperation(
            walletId: userWalletId.stringValue,
            operationId: id,
            body: mapper.mapToRequest(safeTransaction: safeTransaction, signature: signature)
        )
        invalidateJointAccountsETag()

        return try mapper.mapToOperation(from: response)
    }

    func rejectOperation(id: String) async throws -> JointAccountOperation? {
        let response = try await tangemApiService.rejectJointAccountOperation(
            walletId: userWalletId.stringValue,
            operationId: id
        )
        invalidateJointAccountsETag()

        return try response.map(mapper.mapToOperation(from:))
    }

    func getOperationsHistory(afterCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage {
        let response = try await tangemApiService.getJointOperationsHistory(
            walletId: userWalletId.stringValue,
            request: JointAccountsDTO.Request.OperationsHistory(afterCursor: afterCursor, limit: limit)
        )

        return mapper.mapToHistoryPage(from: response)
    }

    func getOperationsHistoryDelta(beforeCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage {
        let response = try await tangemApiService.getJointOperationsHistoryDelta(
            walletId: userWalletId.stringValue,
            request: JointAccountsDTO.Request.OperationsHistoryDelta(beforeCursor: beforeCursor, limit: limit)
        )

        return mapper.mapToHistoryPage(from: response)
    }

    func getOperation(id: String, knownETag: String?) async throws -> JointOperationFetchResult {
        do {
            guard let (eTag, response) = try await tangemApiService.getJointOperation(
                walletId: userWalletId.stringValue,
                operationId: id,
                knownETag: knownETag
            ) else {
                return .notModified
            }

            return try .modified(mapper.mapToHistoryItem(from: response), eTag: eTag)
        } catch let error as TangemAPIError where error.code == .notFound {
            throw JointOperationError.operationNotFound
        } catch let error as TangemAPIError where error.code == .forbidden {
            throw JointOperationError.notAMember
        }
    }
}

// MARK: - Private

private extension CommonJointAccountsNetworkService {
    /// Callers persist the write's response locally, so the tag no longer describes the cached listing. Kept, it would
    /// have the next read answer `304` against that cache: once the listing comes back to what it was (an operation
    /// executed before the first poll), the cache is never corrected.
    func invalidateJointAccountsETag() {
        eTagStorage.clearETag(for: .jointAccounts(walletId: userWalletId))
    }
}
