//
//  ShareSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class ShareSheet: ScreenBase<ShareSheetElement> {
    /// The header truncates the shared text, so only its beginning is matched.
    private static let sharedTextPrefixLength = 20

    private lazy var activityList = otherElement(.activityList)
    private lazy var closeButton = activityList.buttons[ShareSheetElement.close.accessibilityIdentifier].firstMatch
    private lazy var dismissRegion = otherElement(.dismissRegion)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the system share sheet") { _ in
            waitAndAssertTrue(activityList, "System share sheet should be displayed")
            return self
        }
    }

    @discardableResult
    func verifySharedText(_ text: String) -> Self {
        XCTContext.runActivity(named: "Verify the share sheet carries '\(text)'") { _ in
            let prefix = String(text.prefix(Self.sharedTextPrefixLength))
            let predicate = NSPredicate(format: "label BEGINSWITH %@", prefix)
            // Scoped to the sheet: the screen underneath keeps showing the same address.
            waitAndAssertTrue(
                activityList.descendants(matching: .any).matching(predicate).firstMatch,
                timeout: .conditional,
                "Share sheet should show the shared text starting with '\(prefix)'"
            )
            return self
        }
    }

    @discardableResult
    func dismiss<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close the system share sheet") { _ in
            if closeButton.exists {
                closeButton.tap()
            } else if dismissRegion.exists {
                tapAboveSheet()
            } else {
                activityList.swipeDown()
            }

            guard activityList.waitForNonExistence(timeout: .conditional) else {
                XCTFail("Share sheet should be dismissed")
                return Destination(app)
            }

            return Destination(app)
        }
    }

    private func tapAboveSheet() {
        let sheetFrame = activityList.frame
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: sheetFrame.midX, dy: sheetFrame.minY / 2))
            .tap()
    }
}

enum ShareSheetElement: String, UIElement {
    case activityList
    case close
    case dismissRegion

    var accessibilityIdentifier: String {
        switch self {
        case .activityList:
            return "ActivityListView"
        case .close:
            return "Close"
        case .dismissRegion:
            return "PopoverDismissRegion"
        }
    }
}
