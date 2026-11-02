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

    /// Asks for the list once, so that what is stored is the backend's answer rather than the last thing this wallet
    /// happened to write.
    func initialize()

    /// - Note: Replaces the stored list, and the unfinished operations riding inside it, with what the endpoint
    /// answers.
    func loadJointAccountsFromRemote() async throws

    /// Re-reads the list every few seconds for as long as the returned token is held, for a screen watching members
    /// join or confirm; once the last token is dropped the polling falls back to its regular pace, or stops when no
    /// account is waiting on anything.
    func requestFrequentUpdates() -> AnyCancellable

    /// Derives the key the account is signed with, has the backend create it and stores what it reports back.
    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws

    /// Takes up a free slot of an existing account, signing the config the creator settled on.
    /// - Note: The invite is spent by the endpoint, so a second call with the same one is turned away.
    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws

    /// Adds this wallet's confirmation of the composition and the address it adds up to, then stores the account the
    /// way the endpoint answers: the last member to confirm is what puts it to work, which the backend decides.
    /// - Returns: The status the endpoint answered with: active once this confirmation was the last one missing.
    /// - Note: Confirming twice, or an account that is active already, changes nothing, so a lost answer costs a
    /// repeat and no more.
    func confirmJointAccount(withConfig config: JointAccountConfirmationConfig) async throws -> JointAccountStatus

    /// Has the backend issue an invite into a free slot of an account this wallet created and stores it beside the
    /// account's other invites, so the slot reads as invited before the list is read again.
    /// - Note: One invite per slot: issuing another replaces the one stored for that slot. The endpoint turns away a
    /// slot that is taken, an account past the pending stage and a wallet other than the creator's.
    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite
}
