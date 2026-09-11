//
//  JointAccountsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// - Note: Separate from `CryptoAccountsRepository` because that one rewrites its list wholesale on every refresh,
/// which a joint account would not survive.
protocol JointAccountsRepository {
    /// - Note: Emits what is stored right away, so the accounts a wallet took part in last time are there to be shown
    /// while the list is being read anew.
    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> { get }

    /// Asks for the list once, so that what is stored is the backend's answer rather than the last thing this wallet
    /// happened to write.
    func initialize()

    /// - Note: Replaces the stored list with what the endpoint answers. The invites are stored apart from it and are
    /// left alone, since the endpoint hands them out once and never reports them again.
    func loadJointAccountsFromRemote() async throws

    /// Derives the key the account is signed with, has the backend create it and stores what it reports back — the
    /// invites first, since this is the only moment they can be written down.
    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws
}
