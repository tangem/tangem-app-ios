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
    /// - Note: Emits what it has right away, since the accounts list waits for every source.
    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> { get }

    /// - Returns: The account, stored by then, and the invites, which are not — see `JointAccountInvite`.
    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws -> JointAccountCreationResult
}
