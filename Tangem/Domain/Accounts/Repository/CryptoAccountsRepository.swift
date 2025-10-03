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

protocol CryptoAccountsRepository {
    /// Includes all crypto accounts, including archived ones.
    var totalCryptoAccountsCount: Int { get }
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> { get }

    func initialize(forUserWalletWithId userWalletId: UserWalletId)
    func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [TokenItem])
    func removeCryptoAccount<T: Hashable>(withIdentifier identifier: T)
}
