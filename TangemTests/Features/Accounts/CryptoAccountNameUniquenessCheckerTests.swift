//
//  CryptoAccountNameUniquenessCheckerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CryptoAccountNameUniquenessChecker")
struct CryptoAccountNameUniquenessCheckerTests {
    @Test("The name the backend gave the collectibles account stays free for the wallet's own accounts")
    func collectiblesAccountNameStaysFree() {
        let remoteState = CryptoAccountsRemoteState(
            nextCryptoDerivationIndex: 1,
            nextJointDerivationIndex: nil,
            accounts: [
                Fixtures.account(derivationIndex: 0, type: .crypto, name: nil),
                Fixtures.account(derivationIndex: 999799, type: .collectibles, name: "Collectibles"),
            ]
        )
        let sut = CryptoAccountNameUniquenessChecker(remoteState: remoteState)

        #expect(sut.isNameUnique("Collectibles"))
    }
}

// MARK: - Helpers

private extension CryptoAccountNameUniquenessCheckerTests {
    enum Fixtures {
        static func account(derivationIndex: Int, type: AccountType, name: String?) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: derivationIndex,
                type: type,
                name: name,
                icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
                tokens: [],
                grouping: .none,
                sorting: .manual
            )
        }
    }
}
