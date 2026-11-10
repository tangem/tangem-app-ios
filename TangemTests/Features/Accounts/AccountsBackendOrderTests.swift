//
//  AccountsBackendOrderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("AccountModelUtils.ordered")
struct AccountsBackendOrderTests {
    @Test("Accounts of every kind follow the backend order, accounts it does not list go last in their own order")
    func accountsFollowBackendOrder() {
        let accounts = [Self.main, Self.second, Self.unlisted, Self.joint, Self.packs]
        let accountsOrder = [Self.packs, Self.second, Self.joint, Self.main]

        let ordered = AccountModelUtils.ordered(accounts, by: accountsOrder) { $0.toPersistentIdentifier() }

        #expect(ordered == [Self.packs, Self.second, Self.joint, Self.main, Self.unlisted])
    }
}

// MARK: - Helpers

private extension AccountsBackendOrderTests {
    static let main = CryptoAccountDerivationIdentity(derivationIndex: 0, type: .crypto)
    static let second = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .crypto)
    static let unlisted = CryptoAccountDerivationIdentity(derivationIndex: 2, type: .crypto)
    static let joint = CryptoAccountDerivationIdentity(derivationIndex: 0, type: .joint)
    static let packs = CryptoAccountDerivationIdentity(derivationIndex: 0, type: .collectibles)
}
