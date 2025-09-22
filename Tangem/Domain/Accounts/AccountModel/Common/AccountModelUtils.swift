//
//  AccountModelUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum AccountModelUtils {
    /// Standard Java hash function.
    static func deriveIconColor(from userWalletId: UserWalletId) -> AccountModel.Icon.Color {
        let colors = AccountModel.Icon.Color.allCases
        let hashMultiplier = 31

        let hash = userWalletId.value.reduce(0) { acc, byte in
            return acc &* hashMultiplier &+ Int(byte)
        }

        let colorIndex = (hash & Int.max) % colors.count

        return colors[colorIndex]
    }

    static func isMainAccount(_ derivationIndex: Int) -> Bool {
        derivationIndex == Constants.mainAccountDerivationIndex
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
    }
}
