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
    private var testNames: [(String, String)] {
        [
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
    }

    func testUserWalletNameIndexation() {
        let names = testNames.map(\.0).shuffled()
        let expectedNamesAfterMigration = testNames.map(\.1).sorted()

        let migrationHelper = UserWalletNameIndexationHelper(mode: .migration, names: names)

        let migratedNames = names
            .map { name in
                migrationHelper.suggestedName(name)
            }
            .sorted()

        XCTAssertEqual(migratedNames, expectedNamesAfterMigration)

        XCTAssertEqual(migrationHelper.suggestedName("Wallet"), "Wallet 5")
        XCTAssertEqual(migrationHelper.suggestedName("Note"), "Note 4")
        XCTAssertEqual(migrationHelper.suggestedName("Twin"), "Twin 5")
        XCTAssertEqual(migrationHelper.suggestedName("Start2Coin"), "Start2Coin 2")
        XCTAssertEqual(migrationHelper.suggestedName("Wallet 2.0"), "Wallet 2.0 4")
        XCTAssertEqual(migrationHelper.suggestedName("Tangem Card"), "Tangem Card 2")

        let suggestedNameHelper = UserWalletNameIndexationHelper(mode: .newName, names: migratedNames)
        XCTAssertEqual(suggestedNameHelper.suggestedName("Wallet"), "Wallet 5")
        XCTAssertEqual(suggestedNameHelper.suggestedName("Note"), "Note 4")
        XCTAssertEqual(suggestedNameHelper.suggestedName("Twin"), "Twin 5")
        XCTAssertEqual(suggestedNameHelper.suggestedName("Start2Coin"), "Start2Coin 2")
        XCTAssertEqual(suggestedNameHelper.suggestedName("Wallet 2.0"), "Wallet 2.0 4")
        XCTAssertEqual(suggestedNameHelper.suggestedName("Tangem Card"), "Tangem Card 2")
    }
}
