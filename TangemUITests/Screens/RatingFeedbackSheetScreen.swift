//
//  RatingFeedbackSheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class RatingFeedbackSheetScreen: ScreenBase<RatingFeedbackSheetElement> {
    private lazy var feedbackInput = textField(.feedbackInput)
    private lazy var submitButton = button(.submitButton)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for rating feedback sheet to display") { _ in
            waitAndAssertTrue(feedbackInput, "Feedback input should exist")
        }
        return self
    }

    @discardableResult
    func assertSubmitButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert 'Send feedback' button is displayed") { _ in
            waitAndAssertTrue(submitButton, "'Send feedback' button should exist")
        }
        return self
    }

    @discardableResult
    func enterFeedback(_ text: String) -> Self {
        XCTContext.runActivity(named: "Enter feedback comment '\(text)'") { _ in
            waitAndAssertTrue(feedbackInput, "Feedback input should exist")
            feedbackInput.waitAndTap()
            feedbackInput.typeText(text)
        }
        return self
    }

    @discardableResult
    func tapSubmitButton() -> ExpressStatusBottomSheetScreen {
        XCTContext.runActivity(named: "Tap 'Send feedback' button") { _ in
            waitAndAssertTrue(submitButton, "'Send feedback' button should exist")
            submitButton.waitAndTap()
        }
        return ExpressStatusBottomSheetScreen(app)
    }
}

enum RatingFeedbackSheetElement: String, UIElement {
    case feedbackInput
    case submitButton

    var accessibilityIdentifier: String {
        switch self {
        case .feedbackInput:
            return RatingAccessibilityIdentifiers.feedbackInput
        case .submitButton:
            return RatingAccessibilityIdentifiers.submitFeedbackButton
        }
    }
}
