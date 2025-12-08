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
        // Using `Int32.max` instead of `Int.max` (`Int64.max` in fact)
        // to mimic Kotlin/Java 32-bit signed integer overflow behavior
        let maxInt = Int(Int32.max)

        let hash = userWalletId.value.reduce(0) { acc, byte in
            // Kotlin/Java uses int8 in `ByteSequence` while Swift uses uint8 in `Data`,
            // so we need to convert unsigned byte to a signed one to match the hash value
            let signedByte = Int8(bitPattern: byte)
            return acc &* Constants.hashMultiplier &+ Int(signedByte)
        }

        let colorIndex = (hash & maxInt) % colors.count

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
        static let hashMultiplier = 31
    }
}
