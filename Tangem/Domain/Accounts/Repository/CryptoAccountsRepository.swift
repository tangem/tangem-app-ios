//
//  CryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct AccountsUpdates {
    typealias Update = (config: CryptoAccountPersistentConfig, tokens: [StoredCryptoAccount.Token])

    let hasNewAccount: Bool
    let updates: [Update]
}

protocol CryptoAccountsRepository {
    /// Includes all crypto accounts, including archived ones.
    var totalCryptoAccountsCount: Int { get }
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> { get }

    func initialize(forUserWalletWithId userWalletId: UserWalletId)
    /// Adds the given crypto account if it doesn't exist yet, updates it otherwise.
    func addNewOrUpdateExistingCryptoAccounts(updates: AccountsUpdates) async throws
    func removeCryptoAccount<T: Hashable>(withIdentifier identifier: T)
    func getRemoteState() async throws -> CryptoAccountsRemoteState
}
