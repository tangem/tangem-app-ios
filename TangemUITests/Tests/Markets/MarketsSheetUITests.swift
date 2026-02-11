//
//  MarketsSheetUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsSheetUITests: BaseTestCase {
    private let cardTypes: [CardMockAccessibilityIdentifiers] = [
        .twin,
        .wallet2,
        .wallet,
        .xrpNote,
        .shiba,
        .xlmBird,
        .v3seckp,
        .ring,
        .four12,
    ]

    func testMarketsSheetDisplayed_AllCardTypes() {
        setAllureId(3597)
        for cardType in cardTypes {
            XCTContext.runActivity(named: "Verify Markets sheet displayed for \(cardType.rawValue)") { _ in
                launchApp()

                CreateWalletSelectorScreen(app)
                    .scanMockWallet(name: cardType)
                    .openMarketsSheetWithSwipe()
                    .verifyMarketsSheetIsDisplayed()

                app.terminate()
            }
        }
    }
}
