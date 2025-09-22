//
//  CryptoAccounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// - Warning: DO NOT create a helper/property like `accounts: [CryptoAccountModel]`, as it defeats the purpose of this enum.
enum CryptoAccounts {
    /// A single (i.e. invisible) crypto account per single wallet, should not be rendered in the UI.
    case single(any CryptoAccountModel)

    /// Multiple (i.e. visible) crypto accounts per single wallet, should be rendered in the UI.
    case multiple([any CryptoAccountModel])
}

// MARK: - ExpressibleByArrayLiteral protocol conformance

extension CryptoAccounts: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: any CryptoAccountModel...) {
        self.init(accounts: elements)
    }
}

// MARK: - Convenience extensions

extension CryptoAccounts {
    init(accounts: [any CryptoAccountModel]) {
        switch accounts.count {
        case 0:
            preconditionFailure("CryptoAccounts must be initialized with at least one CryptoAccountModel")
        case 1:
            self = .single(accounts[0])
        default:
            self = .multiple(accounts)
        }
    }
}
