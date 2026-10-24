//
//  JointAccountsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

/// - Note: Separate from `CryptoAccountsRepository` because that one rewrites its list wholesale on every refresh,
/// which a joint account would not survive.
protocol JointAccountsRepository {
    /// What is stored at this moment — the synchronous counterpart of `jointAccountsPublisher`, for the callers
    /// that are building something right now and cannot wait for an emission.
    var jointAccounts: [StoredJointAccount] { get }

    /// - Note: Emits what is stored right away, so the accounts a wallet took part in last time are there to be shown
    /// while the list is being read anew.
    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> { get }

    /// What is stored at this moment — the synchronous counterpart of `jointAccountsInvitesPublisher`.
    var jointAccountsInvites: [StoredJointAccountInvites] { get }

    /// - Note: Kept apart from the accounts because it changes on its own occasions — an account is created once, and
    /// the invites it was handed are written then and never again.
    var jointAccountsInvitesPublisher: AnyPublisher<[StoredJointAccountInvites], Never> { get }

    var jointAccountsPendingOperations: [StoredJointAccountPendingOperations] { get }

    /// - Note: Kept apart from the accounts as well: an operation moves on its own occasions — a co-signer answers,
    /// the relayer executes — and none of them is a change to the account it belongs to.
    var jointAccountsPendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> { get }

    /// Asks for the list once, so that what is stored is the backend's answer rather than the last thing this wallet
    /// happened to write.
    func initialize()

    /// - Note: Replaces the stored list, and the unfinished operations riding inside it, with what the endpoint
    /// answers. The invites are stored apart from both and are left alone, since the endpoint hands them out once and
    /// never reports them again.
    func loadJointAccountsFromRemote() async throws

    func requestFrequentUpdates() -> AnyCancellable

    /// Derives the key the account is signed with, has the backend create it and stores what it reports back — the
    /// invites first, since this is the only moment they can be written down.
    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws

    /// Takes up a free slot of an existing account, signing the config the creator settled on.
    /// - Note: The invite is spent by the endpoint, so a second call with the same one is turned away.
    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws

    /// Confirms the composition an account ended up with, which is what hands it its address and puts it to work.
    /// - Note: The creator's to do, and only once every slot is taken. Repeating it on an account that is active
    /// already succeeds, so a lost answer costs a repeat and no more.
    func activateJointAccount(withConfig config: JointAccountActivationConfig) async throws

    /// Registers the operation a member signed and stores it among the account's.
    /// - Returns: The operation as the endpoint registered it, with that signature already counted.
    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation

    /// Counts a member's signature towards the threshold and stores the operation as the endpoint now reports it.
    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws

    /// Declines the operation on a member's behalf.
    /// - Note: An answer carrying nothing is the endpoint saying the operation is gone, so it is dropped rather than
    /// stored.
    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws
}
