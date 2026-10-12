//
//  TangemPaySelectPlanScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPaySelectPlanScreen: ScreenBase<TangemPaySelectPlanScreenElement> {
    private lazy var planName = staticText(.planName)
    private lazy var selectButton = button(.selectButton)
    private lazy var compareButton = button(.compareButton)
    /// Type-agnostic: the carousel is a ScrollView on iOS 17+ and a TabView below it.
    private lazy var carousel = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.selectPlanCarousel].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Select plan screen") { _ in
            waitAndAssertTrue(selectButton, timeout: .networkRequest, "Select button should be displayed on Select plan screen")
            return self
        }
    }

    @discardableResult
    func verifyPlanName(_ expectedName: String) -> Self {
        XCTContext.runActivity(named: "Verify the selected plan is '\(expectedName)'") { _ in
            // Matched on the label so the wait outlasts the carousel animation.
            let named = app.staticTexts
                .matching(NSPredicate(format: "identifier == %@ AND label == %@", TangemPayAccessibilityIdentifiers.selectPlanName, expectedName))
                .firstMatch
            waitAndAssertTrue(named, "Selected plan should be '\(expectedName)', but was '\(planName.label)'")
            return self
        }
    }

    @discardableResult
    func verifyPlanDetail(_ text: String) -> Self {
        XCTContext.runActivity(named: "Verify the plan detail '\(text)' is displayed") { _ in
            waitAndAssertTrue(app.staticTexts[text].firstMatch, "Plan detail '\(text)' should be displayed")
            return self
        }
    }

    @discardableResult
    func swipeToPlan(named expectedName: String) -> Self {
        XCTContext.runActivity(named: "Swipe the carousel to the '\(expectedName)' plan") { _ in
            carousel.swipeLeft()
            return verifyPlanName(expectedName)
        }
    }

    @discardableResult
    func tapCompare() -> TangemPayComparePlansSheet {
        XCTContext.runActivity(named: "Tap Compare plans") { _ in
            compareButton.waitAndTap()
            return TangemPayComparePlansSheet(app)
        }
    }

    @discardableResult
    func tapSelectExpectingConfirmation() -> TangemPayConfirmPlanScreen {
        XCTContext.runActivity(named: "Tap Select and expect the confirmation screen") { _ in
            selectButton.waitAndTap()
            return TangemPayConfirmPlanScreen(app)
        }
    }

    @discardableResult
    func tapSelectExpectingPlanActivation() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Select and expect the plan to be activated") { _ in
            selectButton.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }
}

enum TangemPaySelectPlanScreenElement: String, UIElement {
    case planName
    case selectButton
    case compareButton

    var accessibilityIdentifier: String {
        switch self {
        case .planName:
            TangemPayAccessibilityIdentifiers.selectPlanName
        case .selectButton:
            TangemPayAccessibilityIdentifiers.selectPlanSelectButton
        case .compareButton:
            TangemPayAccessibilityIdentifiers.selectPlanCompareButton
        }
    }
}
