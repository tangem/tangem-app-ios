//
//  TangemPayOtherNetworksSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayOtherNetworksSheet: ScreenBase<TangemPayOtherNetworksSheetElement> {
    private lazy var title = staticText(.title)
    private lazy var subtitle = staticText(.subtitle)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the Other networks sheet") { _ in
            waitAndAssertTrue(title, timeout: .conditional, "Other networks title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyContent(title expectedTitle: String, subtitle expectedSubtitle: String) -> Self {
        XCTContext.runActivity(named: "Verify the Other networks sheet content") { _ in
            waitAndAssertTrue(title, timeout: .conditional, "Other networks title should be displayed")
            XCTAssertEqual(title.label, expectedTitle, "Title should be '\(expectedTitle)'")

            waitAndAssertTrue(subtitle, "Other networks subtitle should be displayed")
            XCTAssertEqual(subtitle.label, expectedSubtitle, "Subtitle should be '\(expectedSubtitle)'")

            waitAndAssertTrue(closeButton, "Close button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapClose() -> TangemPayChooseNetworkSheet {
        XCTContext.runActivity(named: "Close the Other networks sheet") { _ in
            closeButton.waitAndTap()
            // The Choose network sheet stays in the hierarchy underneath, so dismissal is proven by this sheet leaving.
            XCTAssertTrue(
                title.waitForNonExistence(timeout: .conditional),
                "Other networks sheet should be dismissed"
            )
            return TangemPayChooseNetworkSheet(app)
        }
    }
}

enum TangemPayOtherNetworksSheetElement: String, UIElement {
    case title
    case subtitle
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            TangemPayAccessibilityIdentifiers.otherNetworksSheetTitle
        case .subtitle:
            TangemPayAccessibilityIdentifiers.otherNetworksSheetSubtitle
        case .closeButton:
            TangemPayAccessibilityIdentifiers.otherNetworksSheetCloseButton
        }
    }
}
