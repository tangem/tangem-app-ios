//
//  NFTCollectionsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class NFTCollectionsScreen: Screen {
    let app: XCUIApplication

    private lazy var receiveButton = app.buttons[NFTAccessibilityIdentifiers.collectionsReceiveButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForDisplayed() -> Self {
        XCTContext.runActivity(named: "Wait for NFT collections screen") { _ in
            waitAndAssertTrue(receiveButton, "Receive button should be displayed on the NFT collections screen")
            return self
        }
    }

    @discardableResult
    func tapReceive() -> AccountSelectorSheet {
        XCTContext.runActivity(named: "Tap Receive on the NFT collections screen") { _ in
            receiveButton.waitAndTap()
            return AccountSelectorSheet(app)
        }
    }

    @discardableResult
    func expandCollection(_ collectionName: String) -> Self {
        XCTContext.runActivity(named: "Expand NFT collection '\(collectionName)'") { _ in
            let collection = collectionRow(collectionName)
            waitAndAssertTrue(collection, "Collection '\(collectionName)' should be displayed")
            collection.waitAndTap()
            return self
        }
    }

    @discardableResult
    func openAsset(_ assetName: String) -> NFTAssetDetailsScreen {
        XCTContext.runActivity(named: "Open NFT asset '\(assetName)'") { _ in
            let asset = assetCell(assetName)
            waitAndAssertTrue(asset, "Asset '\(assetName)' should be displayed")
            asset.waitAndTap()
            return NFTAssetDetailsScreen(app)
        }
    }

    // Type-agnostic: the collection row is a disclosure group, not guaranteed to stay a Button.
    private func collectionRow(_ collectionName: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: NFTAccessibilityIdentifiers.collectionRow(name: collectionName))
            .firstMatch
    }

    private func assetCell(_ assetName: String) -> XCUIElement {
        app.buttons[NFTAccessibilityIdentifiers.assetCell(name: assetName)].firstMatch
    }
}
