//
//  CryptoAccounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

/// - Warning: Use `CryptoAccountsBuilder` to create instances of this enum, DO NOT create instances directly.
/// - Warning: DO NOT create a helper/property like `accounts: [CryptoAccountModel]`, as it defeats the purpose of this enum.
@RawCaseName
@CaseFlagable
enum CryptoAccounts {
    /// A single (i.e. invisible) crypto account per single wallet, should not be rendered in the UI.
    case single(any CryptoAccountModel)

    /// Multiple (i.e. visible) crypto accounts per single wallet, should be rendered in the UI.
    case multiple([any CryptoAccountModel])

    var state: State {
        switch self {
        case .single:
            return .single
        case .multiple:
            return .multiple
        }
    }
}

// MARK: - Inner types

extension CryptoAccounts {
    /// Represents the enum cases without associated values.
    enum State: Equatable {
        case single
        case multiple
    }
}
