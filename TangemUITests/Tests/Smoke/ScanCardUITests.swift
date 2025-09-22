//
//  ScanCardUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class ScanCardUITests: BaseTestCase {
    func testScanTwinCard_MainShowed() {
        setAllureId(869)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .twin)
            .validate(cardType: .twin)
    }

    func testScanWallet2Card_MainShowed() {
        setAllureId(865)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
    }

    func testScanWalletCard_MainShowed() {
        setAllureId(867)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .wallet)
            .validate(cardType: .wallet)
    }

    func testScanXrpNoteCard_MainShowed() {
        setAllureId(868)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .xrpNote)
            .validate(cardType: .xrpNote)
    }

    func testScanShibaCard_MainShowed() {
        setAllureId(866)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .shiba)
            .validate(cardType: .shiba)
    }

    func testScanV3EdCard_MainShowed() {
        setAllureId(870)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .xlmBird)
            .validate(cardType: .xlmBird)
    }

    func testScanV3SeckpCard_MainShowed() {
        setAllureId(872)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .v3seckp)
            .validate(cardType: .v3seckp)
    }

    func testScanRing_MainShowed() {
        setAllureId(864)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .ring)
            .validate(cardType: .ring)
    }

    func testScan4_12Card_MainShowed() {
        setAllureId(871)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .four12)
            .validate(cardType: .four12)
    }
}
