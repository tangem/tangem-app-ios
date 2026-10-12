//
//  TangemPayCurrentPlanScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCurrentPlanScreen: ScreenBase<TangemPayCurrentPlanScreenElement> {
    private lazy var changePlanButton = button(.changePlanButton)
    private lazy var fullTermsButton = button(.fullTermsButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Current plan screen") { _ in
            let anyRow = app.staticTexts
                .matching(NSPredicate(format: NSPredicateFormat.identifierBeginsWith.rawValue, TangemPayAccessibilityIdentifiers.currentPlanRow("")))
                .firstMatch
            waitAndAssertTrue(anyRow, timeout: .networkRequest, "Plan rows should be displayed on Current plan screen")
            return self
        }
    }

    @discardableResult
    func verifyPlanName(_ expectedName: String) -> Self {
        XCTContext.runActivity(named: "Verify the current plan is '\(expectedName)'") { _ in
            let name = app.staticTexts
                .matching(NSPredicate(format: "identifier == %@ AND label == %@", TangemPayAccessibilityIdentifiers.currentPlanName, expectedName))
                .firstMatch
            waitAndAssertTrue(name, timeout: .networkRequest, "Current plan should be '\(expectedName)'")
            return self
        }
    }

    @discardableResult
    func verifySection(_ title: String) -> Self {
        XCTContext.runActivity(named: "Verify the '\(title)' section is displayed") { _ in
            let section = app.staticTexts[TangemPayAccessibilityIdentifiers.currentPlanSection(title)].firstMatch
            waitAndAssertTrue(section, timeout: .networkRequest, "The '\(title)' section should be displayed on Current plan screen")
            return self
        }
    }

    @discardableResult
    func verifyPlanRow(_ label: String, contains value: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(label)' row contains '\(value)'") { _ in
            let row = text(TangemPayAccessibilityIdentifiers.currentPlanRow(label), containing: value)
            waitAndAssertTrue(row, timeout: .networkRequest, "'\(label)' row should contain '\(value)'")
            return self
        }
    }

    @discardableResult
    func verifyChangePlanUnavailable() -> Self {
        XCTContext.runActivity(named: "Verify Change plan button is not displayed") { _ in
            XCTAssertTrue(
                changePlanButton.waitForNonExistence(timeout: .conditional),
                "Change plan button should be hidden while a transition is in progress"
            )
            return self
        }
    }

    @discardableResult
    func tapChangePlan() -> TangemPaySelectPlanScreen {
        XCTContext.runActivity(named: "Tap Change plan") { _ in
            changePlanButton.waitAndTap()
            return TangemPaySelectPlanScreen(app)
        }
    }

    @discardableResult
    func verifyAwaitingDepositBanner(contains value: String) -> Self {
        verifyBanner(TangemPayAccessibilityIdentifiers.currentPlanAwaitingDepositBanner, named: "awaiting deposit", contains: value)
    }

    @discardableResult
    func verifyDowngradeBanner(contains value: String) -> Self {
        verifyBanner(TangemPayAccessibilityIdentifiers.currentPlanDowngradeBanner, named: "downgrade", contains: value)
    }

    @discardableResult
    func verifyFeeChargedBanner(contains value: String) -> Self {
        verifyBanner(TangemPayAccessibilityIdentifiers.currentPlanFeeChargedBanner, named: "fee charged", contains: value)
    }

    @discardableResult
    func waitForAwaitingDepositBannerHidden() -> Self {
        XCTContext.runActivity(named: "Wait for the awaiting deposit banner to disappear") { _ in
            let banner = app.staticTexts[TangemPayAccessibilityIdentifiers.currentPlanAwaitingDepositBanner].firstMatch
            XCTAssertTrue(
                banner.waitForNonExistence(timeout: .networkRequest),
                "The awaiting deposit banner should disappear once the transition is cancelled"
            )
            return self
        }
    }

    @discardableResult
    func tapCancelTransition() -> Self {
        XCTContext.runActivity(named: "Cancel the pending plan transition") { _ in
            notificationBannerButton(TangemPayAccessibilityIdentifiers.currentPlanAwaitingDepositBanner).waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapStayOnPlan() -> TangemPayStayOnPlusSheet {
        XCTContext.runActivity(named: "Tap the stay on plan button on the downgrade banner") { _ in
            notificationBannerButton(TangemPayAccessibilityIdentifiers.currentPlanDowngradeBanner).waitAndTap()
            return TangemPayStayOnPlusSheet(app)
        }
    }

    @discardableResult
    func tapFullTerms() -> TangemPayTermsAndFeesSheet {
        XCTContext.runActivity(named: "Open the full terms from the Current plan screen") { _ in
            fullTermsButton.waitAndTap()
            return TangemPayTermsAndFeesSheet(app)
        }
    }

    @discardableResult
    func tapBack() -> TangemPayMainScreen {
        tapBackButton(to: TangemPayMainScreen.self)
    }

    /// Banners stamp their identifier onto every element inside, so the text is matched by type and label.
    private func text(_ identifier: String, containing value: String) -> XCUIElement {
        app.staticTexts
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS[c] %@", identifier, value))
            .firstMatch
    }

    @discardableResult
    private func verifyBanner(_ identifier: String, named name: String, contains value: String) -> Self {
        XCTContext.runActivity(named: "Verify the \(name) banner contains '\(value)'") { _ in
            waitAndAssertTrue(
                text(identifier, containing: value),
                timeout: .networkRequest,
                "The \(name) banner should contain '\(value)'"
            )
            return self
        }
    }
}

enum TangemPayCurrentPlanScreenElement: String, UIElement {
    case changePlanButton
    case fullTermsButton

    var accessibilityIdentifier: String {
        switch self {
        case .changePlanButton:
            TangemPayAccessibilityIdentifiers.currentPlanChangeButton
        case .fullTermsButton:
            TangemPayAccessibilityIdentifiers.currentPlanFullTermsButton
        }
    }
}
