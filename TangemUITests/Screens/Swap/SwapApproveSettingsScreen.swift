//
//  SwapApproveSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SwapApproveSettingsScreen: ScreenBase<SwapApproveSettingsScreenElement> {
    enum ApprovePolicy: String, CaseIterable {
        case transaction = "Transaction"
        case unlimited = "Unlimited"
    }

    private lazy var descriptionText = staticText(.description)
    private lazy var confirmButton = button(.confirmButton)
    private lazy var learnMoreLink = app.links.matching(NSPredicate(format: "label == %@", Constants.learnMoreTitle)).firstMatch
    private lazy var browserTopBar = app.otherElements[Constants.browserTopBar].firstMatch

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for approve settings to display") { _ in
            waitAndAssertTrue(confirmButton, "Approve settings Confirm button should be displayed")
            return self
        }
    }

    @discardableResult
    func assertTitle() -> Self {
        XCTContext.runActivity(named: "Assert approve settings title is '\(Constants.title)'") { _ in
            let approveTitle = staticTexts(.title)
                .matching(NSPredicate(format: "label == %@", Constants.title))
                .firstMatch
            waitAndAssertTrue(approveTitle, "Approve settings title should be '\(Constants.title)'")
            return self
        }
    }

    @discardableResult
    func assertPermissionDescriptionDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert DEX permission description is displayed") { _ in
            waitAndAssertTrue(descriptionText, "Approve description should exist")
            XCTAssertTrue(
                descriptionText.label.contains(Constants.descriptionFragment),
                "Approve description should explain the DEX permission, but was '\(descriptionText.label)'"
            )
            return self
        }
    }

    @discardableResult
    func assertLearnMoreLinkDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert '\(Constants.learnMoreTitle)' link is displayed") { _ in
            waitAndAssertTrue(learnMoreLink, "'\(Constants.learnMoreTitle)' link should be displayed")
            return self
        }
    }

    @discardableResult
    func openLearnMoreAndAssertArticleHost(_ host: String) -> Self {
        XCTContext.runActivity(named: "Open '\(Constants.learnMoreTitle)' and assert the article on '\(host)' is opened") { _ in
            learnMoreLink.waitAndTap()
            waitForBrowserOpened()
            waitAndAssertTrue(browserTopBar, "In-app browser top bar should be displayed")
            let addressField = browserTopBar.buttons
                .matching(identifier: Constants.browserAddressField)
                .matching(NSPredicate(format: "value CONTAINS[c] %@", host))
                .firstMatch
            waitAndAssertTrue(addressField, timeout: .networkRequest, "In-app browser should open a page on '\(host)'")
            browserTopBar.buttons
                .matching(NSPredicate(
                    format: "identifier != %@ AND identifier != %@",
                    Constants.browserAddressField,
                    Constants.browserPageFormatButton
                ))
                .firstMatch
                .waitAndTap()
            XCTAssertTrue(browserTopBar.waitForNonExistence(timeout: .robustUIUpdate), "In-app browser should close")
            return self
        }
    }

    @discardableResult
    func assertAmountRow(tokenSymbol: String, policy: ApprovePolicy) -> Self {
        XCTContext.runActivity(named: "Assert approve amount row shows '\(tokenSymbol)' with '\(policy.rawValue)' policy") { _ in
            let rowTitle = policyRowElement(labeled: "\(Constants.amountRowTitlePrefix) \(tokenSymbol)")
            waitAndAssertTrue(rowTitle, "Approve amount row for '\(tokenSymbol)' should be displayed")
            waitAndAssertTrue(policyRowElement(labeled: policy.rawValue), "Approve policy '\(policy.rawValue)' should be selected in the amount row")
            return self
        }
    }

    @discardableResult
    func openPolicyMenu(currentPolicy: ApprovePolicy) -> Self {
        XCTContext.runActivity(named: "Open approve policy menu") { _ in
            let currentValue = policyRowElement(labeled: currentPolicy.rawValue)
            waitAndAssertTrue(currentValue, "Current approve policy '\(currentPolicy.rawValue)' should be displayed")
            currentValue.tap()
            waitAndAssertTrue(policyMenuItem(.unlimited), "Approve policy menu should open")
            return self
        }
    }

    @discardableResult
    func assertPolicyOptionsDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert all approve policy options are available") { _ in
            for policy in ApprovePolicy.allCases {
                waitAndAssertTrue(policyMenuItem(policy), "Approve policy option '\(policy.rawValue)' should be available")
            }
            return self
        }
    }

    @discardableResult
    func assertPolicySelectedInMenu(_ policy: ApprovePolicy) -> Self {
        XCTContext.runActivity(named: "Assert '\(policy.rawValue)' approve policy is marked as selected") { _ in
            let item = policyMenuItem(policy)
            waitAndAssertTrue(item, "Approve policy option '\(policy.rawValue)' should exist")
            XCTAssertTrue(item.isSelected, "Approve policy option '\(policy.rawValue)' should be marked as selected")
            for other in ApprovePolicy.allCases where other != policy {
                XCTAssertFalse(policyMenuItem(other).isSelected, "Approve policy option '\(other.rawValue)' should not be selected")
            }
            return self
        }
    }

    @discardableResult
    func selectPolicy(_ policy: ApprovePolicy) -> Self {
        XCTContext.runActivity(named: "Select '\(policy.rawValue)' approve policy") { _ in
            policyMenuItem(policy).waitAndTap()
            XCTAssertTrue(
                policyMenuItem(policy).waitForNonExistence(timeout: .robustUIUpdate),
                "Approve policy menu should close after selecting '\(policy.rawValue)'"
            )
            return self
        }
    }

    @discardableResult
    func assertConfirmButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert approve settings Confirm button is displayed") { _ in
            waitAndAssertTrue(confirmButton, "Approve settings Confirm button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapConfirm() -> SendSwapProviderSelectorScreen {
        XCTContext.runActivity(named: "Confirm approve settings") { _ in
            confirmButton.waitAndTap()
            XCTAssertTrue(confirmButton.waitForNonExistence(timeout: .robustUIUpdate), "Approve settings should close after confirming")
            return SendSwapProviderSelectorScreen(app)
        }
    }

    private func policyRowElement(labeled label: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: SendAccessibilityIdentifiers.swapApprovePolicyRow)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    private func policyMenuItem(_ policy: ApprovePolicy) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "label == %@ AND identifier != %@", policy.rawValue, SendAccessibilityIdentifiers.swapApprovePolicyRow))
            .firstMatch
    }
}

enum SwapApproveSettingsScreenElement: String, UIElement {
    case title
    case description
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            SendAccessibilityIdentifiers.swapProviderSelectorTitle
        case .description:
            SendAccessibilityIdentifiers.swapApproveDescription
        case .confirmButton:
            SendAccessibilityIdentifiers.swapApproveConfirmButton
        }
    }
}

private extension SwapApproveSettingsScreen {
    enum Constants {
        static let title = "Give Permission"
        static let descriptionFragment = "Decentralized exchanges require permission to interact with your wallet"
        static let learnMoreTitle = "Learn more"
        static let amountRowTitlePrefix = "Amount"
        static let browserTopBar = "TopBrowserBar"
        static let browserAddressField = "URL"
        static let browserPageFormatButton = "PageFormatMenuButton"
    }
}
