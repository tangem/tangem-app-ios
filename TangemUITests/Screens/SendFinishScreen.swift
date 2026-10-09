//
//  SendFinishScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendFinishScreen: ScreenBase<SendFinishScreenElement> {
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var transactionTime = staticText(.transactionTime)
    private lazy var exploreButton = button(.exploreButton)
    private lazy var shareButton = button(.shareButton)
    private lazy var closeButton = button(.closeButton)
    private lazy var amountValue = staticText(.amountValue)

    func isDisplayed(timeout: TimeInterval) -> Bool {
        headerTitle.waitForExistence(timeout: timeout)
    }

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for display: Send Finish Screen") { _ in
            waitAndAssertTrue(headerTitle, "Finish header title should be displayed")
            waitAndAssertTrue(transactionTime, "Transaction time should be displayed")
            waitAndAssertTrue(closeButton, "Close button should be displayed")
            return self
        }
    }

    @discardableResult
    func assertHeaderTitle(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Assert finish header title is '\(expected)'") { _ in
            waitAndAssertTrue(headerTitle, "Finish header title should be displayed")
            let predicate = NSPredicate(format: "label == %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: headerTitle)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Finish header title should be '\(expected)' but was '\(headerTitle.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapExploreButton() -> Self {
        XCTContext.runActivity(named: "Tap Explore button on Send Finish screen") { _ in
            waitAndAssertTrue(exploreButton, "Explore button should exist")
            exploreButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func dismissBrowser() -> Self {
        XCTContext.runActivity(named: "Dismiss in-app browser") { _ in
            app.otherElements["TopBrowserBar"].buttons["Close"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCloseButton() -> TokenScreen {
        XCTContext.runActivity(named: "Tap Close button on Send Finish screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist")
            closeButton.waitAndTap()
        }
        return TokenScreen(app)
    }

    @discardableResult
    func assertAmountDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert amount block is displayed on the success screen") { _ in
            waitAndAssertTrue(amountValue, "Amount value should be displayed on the success screen")
            return self
        }
    }

    @discardableResult
    func assertTransactionTimeDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the operation date and time are displayed") { _ in
            waitAndAssertTrue(transactionTime, "Transaction date and time should be displayed")
            XCTAssertTrue(
                transactionTime.label.contains { $0.isNumber },
                "Transaction date and time should contain digits, but was '\(transactionTime.label)'"
            )
            return self
        }
    }

    @discardableResult
    func assertSwapSourceAmount(containsLabels labels: [[String]]) -> Self {
        XCTContext.runActivity(named: "Assert the send block contains \(labels)") { _ in
            assertBlock(SendAccessibilityIdentifiers.finishSourceAmountBlock, containsLabels: labels, blockName: "Send")
            return self
        }
    }

    @discardableResult
    func assertSwapDestinationAmount(containsLabels labels: [[String]]) -> Self {
        XCTContext.runActivity(named: "Assert the receive block contains \(labels)") { _ in
            assertBlock(SendAccessibilityIdentifiers.finishDestinationAmountBlock, containsLabels: labels, blockName: "Receive")
            return self
        }
    }

    @discardableResult
    func assertSwapProvider(containsLabels labels: [[String]]) -> Self {
        XCTContext.runActivity(named: "Assert the provider block contains \(labels)") { _ in
            assertBlock(SendAccessibilityIdentifiers.finishProviderBlock, containsLabels: labels, blockName: "Provider")
            return self
        }
    }

    @discardableResult
    func assertSwapProviderLogoDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the provider logo is displayed") { _ in
            let logo = app.images.matching(identifier: SendAccessibilityIdentifiers.finishProviderBlock).firstMatch
            waitAndAssertTrue(logo, "Provider logo should be displayed")
            return self
        }
    }

    @discardableResult
    func assertNetworkFee(containsLabels labels: [[String]]) -> Self {
        XCTContext.runActivity(named: "Assert the network fee block contains \(labels)") { _ in
            assertBlock(SendAccessibilityIdentifiers.networkFeeBlock, containsLabels: labels, blockName: "Network fee")
            return self
        }
    }

    @discardableResult
    func assertExploreButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert 'Explore' button is displayed") { _ in
            waitAndAssertTrue(exploreButton, "Explore button should be displayed")
            return self
        }
    }

    @discardableResult
    func assertCloseButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert 'Close' button is displayed") { _ in
            waitAndAssertTrue(closeButton, "Close button should be displayed")
            return self
        }
    }

    func closeToStakingDetails() -> StakingDetailsScreen {
        XCTContext.runActivity(named: "Tap Close and return to staking details") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist")
            closeButton.waitAndTap()
            XCTAssertTrue(
                headerTitle.waitForNonExistence(timeout: .robustUIUpdate),
                "Send finish screen should be dismissed before returning to staking details"
            )
            return StakingDetailsScreen(app)
        }
    }

    private func assertBlock(_ identifier: String, containsLabels expectedLabels: [[String]], blockName: String) {
        let blockTexts = app.staticTexts.matching(identifier: identifier)
        waitAndAssertTrue(blockTexts.firstMatch, "\(blockName) block should be displayed")
        let labels = blockTexts.allElementsBoundByIndex.map(\.label)
        for parts in expectedLabels {
            XCTAssertTrue(
                labels.contains { label in parts.allSatisfy { label.contains($0) } },
                "\(blockName) block should have a text containing \(parts), but had \(labels)"
            )
        }
    }
}

enum SendFinishScreenElement: String, UIElement {
    case headerTitle
    case transactionTime
    case exploreButton
    case shareButton
    case closeButton
    case amountValue

    var accessibilityIdentifier: String {
        switch self {
        case .headerTitle:
            return SendAccessibilityIdentifiers.finishHeader
        case .transactionTime:
            return SendAccessibilityIdentifiers.finishTransactionTime
        case .exploreButton:
            return SendAccessibilityIdentifiers.finishExploreButton
        case .shareButton:
            return SendAccessibilityIdentifiers.finishShareButton
        case .closeButton:
            return SendAccessibilityIdentifiers.sendViewNextButton
        case .amountValue:
            return SendAccessibilityIdentifiers.finishAmountValue
        }
    }
}
