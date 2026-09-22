//
//  CryptoAccountIdMintingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
@testable import Tangem

/// The vectors below pin the formula the backend mints account identifiers with. A drift here means every existing
/// account stops answering to the identifier the backend already knows it by.
@Suite("Tests for how `CryptoAccountModelId` mints the backend identifier")
struct CryptoAccountIdMintingTests {
    @Test("The wallet's own account mints byte-for-byte the identifier it has always been known by")
    func cryptoAccountMintsTheHistoricalIdentifier() {
        let accountId = CryptoAccountModelId(
            userWalletId: Fixtures.userWalletId,
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 7, type: .crypto)
        )

        #expect(accountId.rawValue.hexString.lowercased() == "25fbe9f84015dbf3deed592b4af13de19dcafdaf729d58add39b4d6816a69780")
    }

    @Test("A joint account appends its kind to the same formula, which is all that keeps the identifiers apart")
    func jointAccountMintsWithTheKindSuffix() {
        let jointAccountId = CryptoAccountModelId(
            userWalletId: Fixtures.userWalletId,
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 7, type: .joint)
        )

        // SHA256 of the crypto formula's bytes with "joint" appended
        #expect(jointAccountId.rawValue.hexString.lowercased() == "47bc9144efbc17b51bf08fde5bf30f7bf7ebbff582d18f45b65820a8437963ac")
    }
}

// MARK: - Fixtures

private extension CryptoAccountIdMintingTests {
    enum Fixtures {
        static let userWalletId = UserWalletId(
            value: Data(hexString: "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F")
        )
    }
}
