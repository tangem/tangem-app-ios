//
//  NFTAssetDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class NFTAssetDetailsScreen: Screen {
    let app: XCUIApplication

    private lazy var sendButton = app.buttons[NFTAccessibilityIdentifiers.assetDetailsSendButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func tapSend() -> SendScreen {
        XCTContext.runActivity(named: "Tap Send on the NFT asset details screen") { _ in
            waitAndAssertTrue(sendButton, "Send button should be displayed on the NFT asset details screen")
            sendButton.waitAndTap()
            return SendScreen(app)
        }
    }
}
