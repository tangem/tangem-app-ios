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
    private var existingNameTestCases: [(String, String)] {
        [
            ("Wallet 2", /*     -> */ "Wallet 2"),
            ("Wallet", /*       -> */ "Wallet"),
            ("Wallet 2", /*     -> */ "Wallet 2"),
            ("Wallet", /*       -> */ "Wallet 3"),
            ("Wallet", /*       -> */ "Wallet 4"),
            ("Note", /*         -> */ "Note"),
            ("Note", /*         -> */ "Note 2"),
            ("Note", /*         -> */ "Note 3"),
            ("Twin 1", /*       -> */ "Twin 1"),
            ("Twin", /*         -> */ "Twin 2"),
            ("Twin 3", /*       -> */ "Twin 3"),
            ("Twin", /*         -> */ "Twin 4"),
            ("Start2Coin 1", /* -> */ "Start2Coin 1"),
            ("Start2Coin 1", /* -> */ "Start2Coin 1"),
            ("Start2Coin 1", /* -> */ "Start2Coin 1"),
            ("Tangem Card", /*  -> */ "Tangem Card"),
            ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
            ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
            ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
        ]
    }

    private var newNameTestCases: [(String, String)] {
        [
            ("Wallet", "Wallet 5"),
            ("Note", "Note 4"),
            ("Twin", "Twin 5"),
            ("Start2Coin", "Start2Coin 2"),
            ("Wallet 2.0", "Wallet 2.0 4"),
            ("Tangem Card", "Tangem Card 2"),
        ]
    }

    func testUserWalletNameIndexation() {
        let numberOfShuffleTests = 10

        for testNumber in 1 ... numberOfShuffleTests {
            var generator = SeededNumberGenerator(seed: testNumber, length: existingNameTestCases.count)
            XCTAssertNotNil(generator)

            let existingNames = existingNameTestCases.map(\.0).shuffled(using: &generator!)
            let expectedNamesAfterMigration = existingNameTestCases.map(\.1).sorted()

            let nameMigrationHelper = UserWalletNameIndexationHelper(mode: .migration, names: existingNames)

            let migratedNames = existingNames
                .map { name in
                    nameMigrationHelper.suggestedName(name)
                }
                .sorted()
            XCTAssertEqual(migratedNames, expectedNamesAfterMigration)

            for newNameTestCase in newNameTestCases {
                XCTAssertEqual(nameMigrationHelper.suggestedName(newNameTestCase.0), newNameTestCase.1)
            }

            let newNameHelper = UserWalletNameIndexationHelper(mode: .newName, names: migratedNames)
            for newNameTestCase in newNameTestCases {
                XCTAssertEqual(newNameHelper.suggestedName(newNameTestCase.0), newNameTestCase.1)
            }
        }
    }
}

private class SeededNumberGenerator: RandomNumberGenerator {
    private let values: [UInt64]
    private var index: Int = 0

    init?(seed: Int, length: Int) {
        guard length >= 1 else { return nil }

        srand48(seed)

        values = (1 ... length)
            .map { _ in
                let randomValue = drand48()
                return UInt64(randomValue * Double(UInt64.max - 1))
            }
    }

    func next() -> UInt64 {
        let value = values[index]
        if index < values.count - 1 {
            index += 1
        } else {
            index = 0
        }
        return value
    }
}
