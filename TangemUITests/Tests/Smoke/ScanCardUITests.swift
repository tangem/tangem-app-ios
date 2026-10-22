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

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .twin)
            .validate(cardType: .twin)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanWallet2Card_MainShowed() {
        setAllureId(865)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanWallet3Card_MainShowed() {
        setAllureId(10835)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet3)
            .validate(cardType: .wallet3)
    }

    func testScanWalletCard_MainShowed() {
        setAllureId(867)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .validate(cardType: .wallet)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanXrpNoteCard_MainShowed() {
        setAllureId(868)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .validate(cardType: .xrpNote)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanShibaCard_MainShowed() {
        setAllureId(866)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .shiba)
            .validate(cardType: .shiba)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanV3EdCard_MainShowed() {
        setAllureId(870)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xlmBird)
            .validate(cardType: .xlmBird)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanV3SeckpCard_MainShowed() {
        setAllureId(872)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .v3seckp)
            .validate(cardType: .v3seckp)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScanRing_MainShowed() {
        setAllureId(864)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .ring)
            .validate(cardType: .ring)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }

    func testScan4_12Card_MainShowed() {
        setAllureId(871)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .four12)
            .validate(cardType: .four12)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
    }
}
