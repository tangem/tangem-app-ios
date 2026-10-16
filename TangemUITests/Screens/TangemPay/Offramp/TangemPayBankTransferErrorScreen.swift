//
//  TangemPayBankTransferErrorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankTransferErrorScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[Localization.tangempayWithdrawBankErrorGeneralTitle].firstMatch
    private lazy var retryButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonRetry)).firstMatch
    private lazy var closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the bank transfer error screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Error screen should read '\(Localization.tangempayWithdrawBankErrorGeneralTitle)'")
            return self
        }
    }

    @discardableResult
    func verifyRetryableError() -> Self {
        XCTContext.runActivity(named: "Verify the error offers Retry and Close") { _ in
            waitAndAssertTrue(app.staticTexts[Localization.commonTryAgainLater].firstMatch, "Error screen should read '\(Localization.commonTryAgainLater)'")
            waitAndAssertTrue(retryButton, "Retry should be displayed")
            waitAndAssertTrue(closeButton, "Close should be displayed")
            return self
        }
    }

    @discardableResult
    func tapRetry() -> Self {
        XCTContext.runActivity(named: "Tap Retry") { _ in
            XCTAssertTrue(retryButton.waitForState(state: .enabled, for: .conditional), "Retry should be enabled")
            retryButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapClose() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the bank transfer error screen") { _ in
            XCTAssertTrue(closeButton.waitForState(state: .enabled, for: .conditional), "Close should be enabled")
            closeButton.waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .conditional), "Error screen should be dismissed")
            return TangemPayMainScreen(app).waitForScreen()
        }
    }
}
