//
//  JointAccountsNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// The joint accounts of a single wallet, as the backend keeps them.
/// - Note: Creating one is the endpoint's business alone: it mints the account's identifier and adds the entry the
/// creator's own account list holds for it.
/// - Throws: `TangemAPIError`, whose `code` is what gives each refusal below its meaning.
protocol JointAccountsNetworkService {
    /// - Throws: `.conflict` when this owner address already belongs to a joint account, which means the account is to
    /// be looked for among the ones read back rather than created a second time.
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> RemoteJointAccount

    /// Issues the invite of one free slot. A slot issued again gets a new code, and the old link answers 404.
    /// - Returns: The code, which no other answer ever carries, and when it expires — a day after it was issued.
    /// - Throws: `.badRequest` when the slot is out of range, `.forbidden` when this wallet did not create the
    /// account, `.notFound` when it holds no such account, and `.conflict` when the account no longer takes members or
    /// the slot is taken already.
    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite

    /// Every joint account the wallet takes part in, except the archived ones. The composition changes inside other
    /// people's wallets, which leaves no trace on this one, so the list is asked about often.
    /// - Returns: `.notModified` when the list is what it was when `knownETag` was handed out — the caller keeps the
    /// tag of the answer it has stored and sends it back — so that nothing is written over what is stored.
    func getJointAccounts(knownETag: String?) async throws -> JointAccountsRemoteState

    /// - Throws: `.notFound` when there is no such invite, and `.conflict` when it has been spent or this wallet
    /// already holds a slot of the account it invites to.
    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview

    /// Spends an invite on a slot and, if it was the last one free, has the endpoint work out the account's address.
    /// - Throws: `.conflict`, which is the end of that invite unless it came of the address being registered already.
    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> RemoteJointAccount

    /// - Throws: `.forbidden` when this wallet's slot is not the creator's, and `.conflict` while a slot is still free
    /// or when what is being confirmed differs from what the account holds.
    /// - Note: Activating an account that is active already succeeds, so a lost answer costs a repeat and no more.
    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount

    /// Adds this member's confirmation of the composition and the address it adds up to; the last one puts the
    /// account to work.
    /// - Throws: `.badRequest` when the address is not in lower case or the signature is not this member's,
    /// `.forbidden` when this wallet is not a member, `.notFound` when no account has this address, and `.conflict`
    /// when the account is cancelled or what is being confirmed differs from what the account holds.
    /// - Note: Confirming twice, or confirming an account that is active already, changes nothing, so a lost answer
    /// costs a repeat and no more.
    func confirmJointAccount(blob: JointAccountConfirmationBlob) async throws -> RemoteJointAccount

    // MARK: - Operations

    /// - Returns: The operation with the initiator's signature already counted; in `pending` right away when the
    /// account's threshold is 1.
    /// - Throws: `.conflict` while the network already carries an unfinished operation of this account.
    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation

    /// - Returns: The operation with this member's signature counted in; reaching the threshold hands it to the relayer.
    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data) async throws -> JointAccountOperation

    /// - Returns: The operation with its progress recounted, or nil when this very call deleted it — the initiator's
    /// reject always does, a co-signer's once the threshold becomes unreachable.
    func rejectOperation(id: String) async throws -> JointAccountOperation?

    // MARK: - Operations history

    func getOperationsHistory(afterCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage

    func getOperationsHistoryDelta(beforeCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage

    func getOperation(id: String, knownETag: String?) async throws -> JointOperationFetchResult
}

/// What a read of the list answers with.
enum JointAccountsRemoteState {
    /// The list is what it was when it was last read, so nothing came back with the answer.
    case notModified
    case changed([RemoteJointAccount], eTag: String?)
}
