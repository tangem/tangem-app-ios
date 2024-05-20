//
//  UserWalletNameIndexationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class UserWalletNameIndexationTests: XCTestCase {
    func testUserWalletNameIndexation() {
        let testNames: [(String, String)] = [
            ("Wallet 2", /*       ->     */ "Wallet 2"),
            ("Wallet", /*         ->     */ "Wallet"),
            ("Wallet 2", /*       ->     */ "Wallet 2"),
            ("Wallet", /*         ->     */ "Wallet 3"),
            ("Wallet", /*         ->     */ "Wallet 4"),
            ("Note", /*           ->     */ "Note"),
            ("Note", /*           ->     */ "Note 2"),
            ("Note", /*           ->     */ "Note 3"),
            ("Twin 1", /*         ->     */ "Twin 1"),
            ("Twin", /*           ->     */ "Twin 2"),
            ("Twin 3", /*         ->     */ "Twin 3"),
            ("Twin", /*           ->     */ "Twin 4"),
            ("Start2Coin 1", /*   ->     */ "Start2Coin 1"),
            ("Start2Coin 1", /*   ->     */ "Start2Coin 1"),
            ("Start2Coin 1", /*   ->     */ "Start2Coin 1"),
            ("Tangem Card", /*    ->     */ "Tangem Card"),
            ("Wallet 2.0", /*     ->     */ "Wallet 2.0"),
            ("Wallet 2.0", /*     ->     */ "Wallet 2.0 2"),
            ("Wallet 2.0", /*     ->     */ "Wallet 2.0 3"),
        ]

        let names = testNames.map(\.0)
        let expectedNamesAfterMigration = testNames.map(\.1)

        let helper = UserWalletNameIndexationHelper(mode: .migration, names: names)

        let migratedNames = names.map { name in
            helper.suggestedName(name)
        }

        XCTAssertEqual(migratedNames, expectedNamesAfterMigration)

        XCTAssertEqual(helper.suggestedName("Wallet"), "Wallet 5")
        XCTAssertEqual(helper.suggestedName("Note"), "Note 4")
        XCTAssertEqual(helper.suggestedName("Twin"), "Twin 5")
        XCTAssertEqual(helper.suggestedName("Start2Coin"), "Start2Coin 2")
        XCTAssertEqual(helper.suggestedName("Wallet 2.0"), "Wallet 2.0 4")
        XCTAssertEqual(helper.suggestedName("Tangem Card"), "Tangem Card 2")
    }
}
