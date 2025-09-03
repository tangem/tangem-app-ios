//
//  CryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountsRepository {
    /// Includes all crypto accounts, including archived ones.
    var totalCryptoAccountsCount: Int { get }
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> { get }

    func initialize() async
    func addCryptoAccount(_ cryptoAccountModel: any CryptoAccountModel)
    func removeCryptoAccount(withIdentifier identifier: AnyHashable)
}
