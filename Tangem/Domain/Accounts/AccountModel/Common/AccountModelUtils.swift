//
//  AccountModelUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// [REDACTED_TODO_COMMENT]
enum AccountModelUtils {
    static var maxAccountNameLength: Int { Constants.maxAccountNameLength }
    static var maxNumberOfAccounts: Int { Constants.maxNumberOfAccounts }

    @available(iOS, deprecated: 100000.0, message: "Will be removed after accounts migration is complete ([REDACTED_INFO])")
    static var mainAccountDerivationIndex: Int { Constants.mainAccountDerivationIndex }

    static func mainAccountPersistentConfig(forUserWalletWithId userWalletId: UserWalletId) -> CryptoAccountPersistentConfig {
        let iconColor = deriveMainAccountIconColor(from: userWalletId)

        return CryptoAccountPersistentConfig(
            derivationIndex: Constants.mainAccountDerivationIndex,
            name: nil, // Main account uses a localized name
            iconName: Constants.mainAccountIconName.rawValue,
            iconColor: iconColor.rawValue
        )
    }

    static func isMainAccount(_ derivationIndex: Int) -> Bool {
        derivationIndex == Constants.mainAccountDerivationIndex
    }

    /// A standard Java hash function.
    private static func deriveMainAccountIconColor(from userWalletId: UserWalletId) -> AccountModel.Icon.Color {
        let colors = AccountModel.Icon.Color.allCases
        let hashMultiplier = 31

        let hash = userWalletId.value.reduce(0) { acc, byte in
            return acc &* hashMultiplier &+ Int(byte)
        }

        let colorIndex = (hash & Int.max) % colors.count

        return colors[colorIndex]
    }
}

// MARK: - Convenience extensions

extension AccountModelUtils {
    static func isMainAccount(_ derivationIndex: UInt32) -> Bool {
        isMainAccount(Int(derivationIndex))
    }
}

// MARK: - Constants

private extension AccountModelUtils {
    enum Constants {
        static let mainAccountDerivationIndex = 0
        static let mainAccountIconName: AccountModel.Icon.Name = .star
        static let maxAccountNameLength = 20
        static let maxNumberOfAccounts = 20
    }
}
