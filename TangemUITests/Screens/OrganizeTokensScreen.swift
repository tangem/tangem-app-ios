//
//  OrganizeTokensScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
@testable import TangemAssets

final class OrganizeTokensScreen: ScreenBase<OrganizeTokensScreenElement> {
    private lazy var tokensList = scrollView(.tokensList)
    private lazy var sortByBalanceButton = button(.sortByBalanceButton)
    private lazy var groupButton = button(.groupButton)
    private lazy var applyButton = button(.applyButton)

    @discardableResult
    func sortByBalance() -> Self {
        XCTContext.runActivity(named: "Sort tokens by balance") { _ in
            sortByBalanceButton.waitAndTap()
            return self
        }
    }

    func applyChanges() -> MainScreen {
        XCTContext.runActivity(named: "Apply organize tokens changes") { _ in
            applyButton.waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func group() -> Self {
        XCTContext.runActivity(named: "Group tokens by network") { _ in
            groupButton.waitAndTap()
            waitForGroupingState(expectedGrouped: true)
            return self
        }
    }

    @discardableResult
    func ungroup() -> Self {
        XCTContext.runActivity(named: "Ungroup tokens") { _ in
            groupButton.waitAndTap()
            waitForGroupingState(expectedGrouped: false)
            return self
        }
    }

    func isGrouped() -> Bool {
        let groupButtonTitle = groupButton.label.lowercased()
        if groupButtonTitle.contains("ungroup") {
            return true
        }
        if groupButtonTitle.contains("group") {
            return false
        }

        let networkHeaders = tokensList.descendants(matching: .staticText)
            .allElementsBoundByIndex
            .filter { element in
                let text = element.label.lowercased()
                return text.hasSuffix("network")
            }

        if !networkHeaders.isEmpty {
            return true
        }

        let sectionDragIcons = tokensList.descendants(matching: .image)
            .matching(NSPredicate(format: "label == %@", Assets.OrganizeTokens.groupDragAndDropIcon.name))
            .allElementsBoundByIndex

        return !sectionDragIcons.isEmpty
    }

    @discardableResult
    func verifyIsGrouped(_ expectedState: Bool) -> Self {
        XCTContext.runActivity(named: "Verify tokens grouping state is \(expectedState)") { _ in
            let actualState = isGrouped()
            XCTAssertEqual(actualState, expectedState, "Expected grouping state: \(expectedState), but got: \(actualState)")
            return self
        }
    }

    @discardableResult
    func verifyGroupingButtonState(expectedToShowUngroup: Bool) -> Self {
        XCTContext.runActivity(named: "Verify grouping button shows \(expectedToShowUngroup ? "Ungroup" : "Group")") { _ in
            let buttonTitle = groupButton.label
            let showsUngroup = isGroupingButtonShowingUngroup()
            XCTAssertEqual(
                showsUngroup,
                expectedToShowUngroup,
                "Expected button to show \(expectedToShowUngroup ? "Ungroup" : "Group"), but got: '\(buttonTitle)'"
            )
            return self
        }
    }

    @discardableResult
    func drag(one source: String, to destination: String) -> Self {
        XCTContext.runActivity(named: "Drag token '\(source)' to '\(destination)'") { _ in
            let sourceElement = getTokenDragIcon(name: source)
            let destinationElement = getTokenDragIcon(name: destination)
            sourceElement.press(forDuration: 1.0, thenDragTo: destinationElement)
            return self
        }
    }

    /// Returns token order grouped by account, preserving visual order.
    func getTokensOrder() -> TokensOrder {
        struct TokenInfo {
            let outer: Int
            let inner: Int
            let item: Int
            let name: String
        }

        // Using .other to match only top-level SwiftUI views, not child elements
        let allElements = tokensList.descendants(matching: .other)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'token_' AND identifier CONTAINS '_'"))
            .allElementsBoundByIndex

        let parsedTokens: [TokenInfo] = allElements.map { element in
            let identifier = element.identifier
            let components = identifier.components(separatedBy: "_")

            // Format: token_outer_inner_item_name
            XCTAssertGreaterThanOrEqual(components.count, 5, "Invalid token identifier format: \(identifier)")
            XCTAssertEqual(components[0], "token", "Token identifier must start with 'token': \(identifier)")

            return TokenInfo(
                outer: Int(components[1])!,
                inner: Int(components[2])!,
                item: Int(components[3])!,
                name: components[4...].joined(separator: "_")
            )
        }

        // Parse account headers to map outer section -> account key
        let headerElements = tokensList.descendants(matching: .other)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", OrganizeTokensAccessibilityIdentifiers.accountHeaderPrefix + "_"))
            .allElementsBoundByIndex

        var outerToAccountKey: [Int: String] = [:]
        for header in headerElements {
            let parsed = Self.parseAccountHeaderIdentifier(header.identifier)
            outerToAccountKey[parsed.outerSection] = parsed.key
        }

        // Sort all tokens by visual order (outer -> inner -> item)
        let sortedTokens = parsedTokens.sorted {
            if $0.outer != $1.outer { return $0.outer < $1.outer }
            if $0.inner != $1.inner { return $0.inner < $1.inner }
            return $0.item < $1.item
        }

        // Group tokens by outer section while preserving order
        var result: TokensOrder = []
        var currentOuter: Int?
        var currentTokens: [String] = []

        for token in sortedTokens {
            if token.outer != currentOuter {
                // Save previous group if exists
                if let outer = currentOuter {
                    let accountKey = outerToAccountKey[outer] ?? "main_account"
                    result.append((accountKey, currentTokens))
                }
                // Start new group
                currentOuter = token.outer
                currentTokens = [token.name]
            } else {
                currentTokens.append(token.name)
            }
        }

        // Save the last group
        if let outer = currentOuter {
            let accountKey = outerToAccountKey[outer] ?? "main_account"
            result.append((accountKey, currentTokens))
        }

        return result
    }

    @discardableResult
    func verifyTokensOrder(_ expectedOrder: TokensOrder, timeout: TimeInterval = 5.0) -> Self {
        XCTContext.runActivity(named: "Verify tokens order matches expected") { _ in
            let deadline = Date().addingTimeInterval(timeout)
            var actual: TokensOrder = []
            var accountsMatch = false
            var tokensMatch = true

            // Poll until order matches or timeout (handles drag animation settling)
            repeat {
                actual = getTokensOrder()
                accountsMatch = actual.accountNames == expectedOrder.accountNames

                if accountsMatch {
                    tokensMatch = true
                    for (index, expected) in expectedOrder.enumerated() {
                        if actual[index].tokens != expected.tokens {
                            tokensMatch = false
                            break
                        }
                    }
                }

                if accountsMatch, tokensMatch {
                    break
                }
            } while Date() < deadline

            // Final assertions with detailed error messages
            XCTAssertEqual(
                actual.accountNames,
                expectedOrder.accountNames,
                "Accounts order doesn't match. Actual: \(actual.accountNames), Expected: \(expectedOrder.accountNames)"
            )

            for (index, expected) in expectedOrder.enumerated() {
                let actualTokens = actual[index].tokens
                XCTAssertEqual(
                    actualTokens,
                    expected.tokens,
                    "Tokens order for account '\(expected.account)' doesn't match. Actual: \(actualTokens), Expected: \(expected.tokens)"
                )
            }

            return self
        }
    }

    private func getTokenDragIcon(name: String) -> XCUIElement {
        let predicate = NSPredicate(
            format: "label == %@ AND identifier ENDSWITH %@",
            Assets.OrganizeTokens.itemDragAndDropIcon.name,
            "_\(name)"
        )
        let element = tokensList.descendants(matching: .image)
            .matching(predicate)
            .firstMatch

        XCTAssertTrue(element.waitForExistence(timeout: 5.0), "Drag icon for '\(name)' not found")
        return element
    }

    private func isGroupingButtonShowingUngroup() -> Bool {
        let buttonTitle = groupButton.label.lowercased()
        return buttonTitle.contains("ungroup")
    }

    private func waitForGroupingState(expectedGrouped: Bool, timeout: TimeInterval = 5.0) {
        let expectedButtonText = expectedGrouped ? "Ungroup" : "Group"
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedButtonText)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: groupButton)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Timed out waiting for group button to show '\(expectedButtonText)'")
    }

    /// Parses identifier format: organizeTokens_accountHeader_<outerSection>_<accountId>_<accountName>
    private static func parseAccountHeaderIdentifier(_ identifier: String) -> (outerSection: Int, key: String) {
        let prefix = OrganizeTokensAccessibilityIdentifiers.accountHeaderPrefix + "_"
        precondition(identifier.hasPrefix(prefix), "Invalid account header identifier: \(identifier)")

        let rest = String(identifier.dropFirst(prefix.count))
        let parts = rest.components(separatedBy: "_")
        precondition(parts.count >= 3, "Invalid account header format, expected at least 3 parts: \(identifier)")

        let outerSection = Int(parts[0])!
        let accountId = parts[1]
        let accountName = parts[2...].joined(separator: "_")
        return (outerSection: outerSection, key: "\(accountId)_\(accountName)")
    }
}

enum OrganizeTokensScreenElement: String, UIElement {
    case tokensList
    case sortByBalanceButton
    case groupButton
    case applyButton

    var accessibilityIdentifier: String {
        switch self {
        case .tokensList:
            return OrganizeTokensAccessibilityIdentifiers.tokensList
        case .sortByBalanceButton:
            return OrganizeTokensAccessibilityIdentifiers.sortByBalanceButton
        case .groupButton:
            return OrganizeTokensAccessibilityIdentifiers.groupButton
        case .applyButton:
            return OrganizeTokensAccessibilityIdentifiers.applyButton
        }
    }
}
