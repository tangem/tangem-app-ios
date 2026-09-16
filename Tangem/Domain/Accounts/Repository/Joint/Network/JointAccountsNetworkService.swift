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
/// - Throws: `TangemAPIError`, whose `code` is what gives each refusal below its meaning.
protocol JointAccountsNetworkService {
    /// - Returns: The account, and one invite per slot the creator left free — the only time the endpoint hands those
    /// out at all.
    /// - Throws: `.conflict` when this owner address already belongs to a joint account, which means the account is to
    /// be looked for among the ones read back rather than created a second time.
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult

    /// - Returns: Every joint account the wallet takes part in, except the archived ones.
    /// - Note: Nothing caches this: the composition changes inside other people's wallets, which leaves no trace on
    /// this one, so the list is worth reading anew whenever it is shown.
    func getJointAccounts() async throws -> [RemoteJointAccount]

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

    // MARK: - Operations

    /// - Returns: The operation with the initiator's signature already counted; in `pending` right away when the
    /// account's threshold is 1.
    /// - Throws: `.conflict` while the network already carries an unfinished operation of this account.
    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation

    /// - Returns: The operation with this member's signature counted in; reaching the threshold hands it to the relayer.
    func signOperation(id: String, signature: Data) async throws -> JointAccountOperation

    /// - Returns: The operation with its progress recounted, or nil when this very call deleted it — the initiator's
    /// reject always does, a co-signer's once the threshold becomes unreachable.
    func rejectOperation(id: String, blob: JointAccountOperationRejectionBlob) async throws -> JointAccountOperation?
}

struct JointAccountCreationResult {
    let account: RemoteJointAccount
    /// One per slot the creator left free, which is the only time they are ever handed out — see `StoredJointAccountInvite`.
    let invites: [StoredJointAccountInvite]
}
