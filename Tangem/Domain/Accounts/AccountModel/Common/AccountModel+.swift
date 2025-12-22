//
//  AccountModel+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Convenience extensions for Accounts domain models

extension AccountModel {
    func cryptoAccount(with identifier: some Hashable) -> (any CryptoAccountModel)? {
        switch self {
        case .standard(let cryptoAccounts):
            return cryptoAccounts.cryptoAccount(with: identifier)
        }
    }
}

extension CryptoAccounts {
    func cryptoAccount(with identifier: some Hashable) -> (any CryptoAccountModel)? {
        let identifier = identifier.toAnyHashable()

        switch self {
        case .single(let cryptoAccountModel):
            return cryptoAccountModel.id.toAnyHashable() == identifier ? cryptoAccountModel : nil
        case .multiple(let cryptoAccountModels):
            return cryptoAccountModels.first { $0.id.toAnyHashable() == identifier }
        }
    }
}

extension Array where Element == AccountModel {
    func standard() -> AccountModel? {
        first { account in
            if case .standard = account {
                return true
            }

            return false
        }
    }

    func cryptoAccounts() -> [CryptoAccounts] {
        compactMap { account in
            if case .standard(let cryptoAccounts) = account {
                return cryptoAccounts
            }

            return nil
        }
    }

    func cryptoAccount(with identifier: some Hashable) -> (any CryptoAccountModel)? {
        compactMap { $0.cryptoAccount(with: identifier) }.first
    }

    /// When new account types appear (e.g., smart, visa), clarify whether
    /// we should count all accounts together or separately by type.
    var cryptoAccountsCount: Int {
        reduce(0) { count, accountModel in
            switch accountModel {
            case .standard(.single):
                return count + 1
            case .standard(.multiple(let cryptoAccountModels)):
                return count + cryptoAccountModels.count
            }
        }
    }
}

extension Array where Element == CryptoAccounts {
    var hasMultipleAccounts: Bool {
        contains { $0.isMultiple }
    }
}
