//
//  OrganizeTokensScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemAccessibilityIdentifiers
@testable import TangemAssets

final class OrganizeTokensScreen: ScreenBase<OrganizeTokensScreenElement> {
    private lazy var tokensList = scrollView(.tokensList)
    private lazy var sortByBalanceButton = button(.sortByBalanceButton)
    private lazy var groupButton = button(.groupButton)
    private lazy var applyButton = button(.applyButton)
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
    private lazy var sortMenuTrigger = app.descendants(matching: .any)
        .matching(identifier: OrganizeTokensAccessibilityIdentifiers.sortMenuTrigger)
        .firstMatch

    @discardableResult
    func sortByBalance() -> Self {
        XCTContext.runActivity(named: "Sort tokens by balance") { _ in
            openSortMenu()
            sortByBalanceButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func cancelOrganizeTokens() -> MainScreen {
        XCTContext.runActivity(named: "Cancel organize tokens (dismiss sheet)") { _ in
            // Redesign exposes an explicit close button; legacy layout relies on swipe-down dismiss.
            if closeButton.waitForExistence(timeout: .conditional) {
                closeButton.waitAndTap()
            } else {
                let startPoint = tokensList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                let endPoint = startPoint.withOffset(CGVector(dx: 0, dy: 400))
                startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
            }
            return MainScreen(app)
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
            openSortMenu()
            groupButton.waitAndTap()
            waitForGroupingState(expectedGrouped: true)
            return self
        }
    }

    @discardableResult
    func ungroup() -> Self {
        XCTContext.runActivity(named: "Ungroup tokens") { _ in
            openSortMenu()
            groupButton.waitAndTap()
            waitForGroupingState(expectedGrouped: false)
            return self
        }
    }

    func isGrouped() -> Bool {
        _ = tokensList.waitForExistence(timeout: .robustUIUpdate)
        // Use `firstMatch.exists` (atomic snapshot lookup) to avoid both XCUI mid-iteration races and the SwiftFormat empty_count rewrite.
        let networkHeader = tokensList.descendants(matching: .staticText)
            .matching(NSPredicate(format: "label ENDSWITH[c] %@", "network"))
            .firstMatch
        if networkHeader.exists {
            return true
        }

        let sectionDragIcon = tokensList.descendants(matching: .image)
            .matching(NSPredicate(format: "label == %@", Assets.OrganizeTokens.groupDragAndDropIcon.name))
            .firstMatch
        return sectionDragIcon.exists
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

    private func openSortMenu() {
        // Redesign wraps sort/group in a dropdown menu; legacy exposes them as direct buttons.
        if sortMenuTrigger.waitForExistence(timeout: .conditional) {
            sortMenuTrigger.waitAndTap()
        }
    }

    private func waitForGroupingState(expectedGrouped: Bool, timeout: TimeInterval = 5.0) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isGrouped() == expectedGrouped { return }
        }
        XCTFail("Timed out waiting for grouping state to be \(expectedGrouped)")
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
    case sortMenuTrigger

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
        case .sortMenuTrigger:
            return OrganizeTokensAccessibilityIdentifiers.sortMenuTrigger
        }
    }
}
