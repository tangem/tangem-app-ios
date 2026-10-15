//
//  TransactionHistorySyncMetadataHashingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Transaction history sync metadata hashing")
struct TransactionHistorySyncMetadataHashingTests {
    @Test("The migration helper rekeys a stored user wallet ID to the pinned digest")
    func migrationHelperOutputIsPinned() {
        let migratedWalletID = CommonAppDatabaseMigrationHelper()
            .expressSyncMetadataV3WalletID(fromV2UserWalletID: Fixtures.userWalletIDStringValue)

        #expect(migratedWalletID == Fixtures.hashedUserWalletID)
    }

    @Test("The hashed user wallet ID is pinned and differs from both the raw and the analytics IDs")
    func hashedUserWalletIDIsPinned() {
        let userWalletId = UserWalletId(stringValue: Fixtures.userWalletIDStringValue)

        let hashedUserWalletID = TransactionHistorySyncMetadataUserWalletIDHasher.hash(userWalletId)

        #expect(hashedUserWalletID == Fixtures.hashedUserWalletID)
        #expect(hashedUserWalletID != userWalletId.stringValue)
        #expect(hashedUserWalletID != userWalletId.hashedStringValue)
    }
}

// MARK: - Fixtures

private extension TransactionHistorySyncMetadataHashingTests {
    enum Fixtures {
        static let userWalletIDStringValue = "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F"
        static let hashedUserWalletID = "241C5C03FBB5BA7F0E4615165EB8D265AEDACC876527BEB8AB4F1867F9BF1504"
    }
}
