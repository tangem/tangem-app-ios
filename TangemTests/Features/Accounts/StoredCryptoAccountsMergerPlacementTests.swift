//
//  StoredCryptoAccountsMergerPlacementTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("StoredCryptoAccountsMerger placement")
struct StoredCryptoAccountsMergerPlacementTests {
    @Test("A new account goes where it is placed, the existing accounts keep their order", arguments: [
        (Placement.first, [2, 0, 1]),
        (Placement.last, [0, 1, 2]),
    ])
    func newAccountFollowsPlacement(placement: Placement, expectedIndices: [Int]) {
        let merger = StoredCryptoAccountsMerger(
            preserveTokensWhileMergingAccounts: true,
            newAccountsPlacement: placement
        )

        let result = merger.merge(oldAccounts: [Self.account(0), Self.account(1)], newAccounts: [Self.account(2)])
        let indices = result.accounts.map(\.derivationIdentity.derivationIndex)

        #expect(indices == expectedIndices)
        #expect(result.isDirty)
    }
}

// MARK: - Arguments

extension StoredCryptoAccountsMergerPlacementTests {
    typealias Placement = StoredCryptoAccountsMerger.NewAccountsPlacement
}

// MARK: - Helpers

private extension StoredCryptoAccountsMergerPlacementTests {
    static func account(_ derivationIndex: Int) -> StoredCryptoAccount {
        let config = CryptoAccountPersistentConfig(
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .crypto),
            name: "Account \(derivationIndex)",
            icon: AccountModel.CompositeIcon(name: .package, color: .azure)
        )

        return StoredCryptoAccount(config: config, tokenListAppearance: .default, tokens: [])
    }
}
