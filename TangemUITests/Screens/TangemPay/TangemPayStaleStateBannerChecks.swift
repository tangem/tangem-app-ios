//
//  TangemPayStaleStateBannerChecks.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

/// Stale-state banners are rendered both on the main screen and on Payment account.
protocol TangemPayStaleStateBannerChecks: Screen {}

extension TangemPayStaleStateBannerChecks {
    @discardableResult
    func verifySessionExpiredBanner() -> Self {
        XCTContext.runActivity(named: "Verify session expired banner is displayed") { _ in
            waitAndAssertTrue(sessionExpiredBanner, timeout: .networkRequest, "Session expired banner should be displayed")
            waitAndAssertTrue(
                bannerText(containing: "Payment account session expired"),
                "Session expired banner should show the title"
            )
            waitAndAssertTrue(
                bannerText(containing: "Use your card or ring to renew session"),
                "Session expired banner should show the description"
            )
            return self
        }
    }

    @discardableResult
    func verifySessionExpiredBannerHidden() -> Self {
        XCTContext.runActivity(named: "Verify session expired banner is NOT displayed") { _ in
            XCTAssertTrue(
                sessionExpiredBanner.waitForNonExistence(timeout: .conditional),
                "Session expired banner should not be displayed when cached data is available"
            )
            return self
        }
    }

    @discardableResult
    func verifyConnectionIssuesBanner() -> Self {
        XCTContext.runActivity(named: "Verify connection issues banner is displayed") { _ in
            waitAndAssertTrue(serviceUnavailableBanner, timeout: .networkRequest, "Connection issues banner should be displayed")
            waitAndAssertTrue(
                bannerText(containing: "Connection issues"),
                "Connection issues banner should show the title"
            )
            waitAndAssertTrue(
                bannerText(containing: "Service unreachable. However, card payments are still working."),
                "Connection issues banner should show the description"
            )
            return self
        }
    }

    @discardableResult
    func verifyConnectionIssuesBannerHidden() -> Self {
        XCTContext.runActivity(named: "Verify connection issues banner is NOT displayed") { _ in
            XCTAssertTrue(
                serviceUnavailableBanner.waitForNonExistence(timeout: .conditional),
                "Connection issues banner should not be displayed when cached data is available"
            )
            return self
        }
    }

    @discardableResult
    func verifyRenewSessionButton() -> Self {
        XCTContext.runActivity(named: "Verify Renew session button is displayed on the banner") { _ in
            let renewButton = notificationBannerButton(TangemPayAccessibilityIdentifiers.sessionExpiredNotification)
            waitAndAssertTrue(renewButton, "Renew session button should be displayed on the session expired banner")
            XCTAssertEqual(renewButton.label, "Renew session", "Banner button should be the Renew session action")
            return self
        }
    }

    private var sessionExpiredBanner: XCUIElement {
        banner(TangemPayAccessibilityIdentifiers.sessionExpiredNotification)
    }

    private var serviceUnavailableBanner: XCUIElement {
        banner(TangemPayAccessibilityIdentifiers.serviceUnavailableNotification)
    }

    /// Type-agnostic: redesign and legacy notifications expose different element types.
    private func banner(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Banner elements are siblings rather than children, so the text cannot be scoped to the banner element.
    private func bannerText(containing text: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
}

extension MainScreen: TangemPayStaleStateBannerChecks {}

extension TangemPayMainScreen: TangemPayStaleStateBannerChecks {}
