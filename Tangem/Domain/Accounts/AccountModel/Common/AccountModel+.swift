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
        case .joint(let jointAccounts):
            return jointAccounts.jointAccount(with: identifier)
        case .tangemPay, .polymarket, .collectibles:
            return nil
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

extension JointAccounts {
    func jointAccount(with identifier: some Hashable) -> (any JointAccountModel)? {
        let identifier = identifier.toAnyHashable()

        return first { $0.id.toAnyHashable() == identifier }
    }
}

extension Array where Element == AccountModel {
    func firstStandard() -> AccountModel? {
        first { account in
            if case .standard = account {
                return true
            }

            return false
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
            case .joint, .tangemPay, .polymarket, .collectibles:
                return count
            }
        }
    }
}
