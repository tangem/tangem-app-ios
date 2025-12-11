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

            // Wait for grouping to take effect
            waitForGroupingState(expectedGrouped: true)
            return self
        }
    }

    @discardableResult
    func ungroup() -> Self {
        XCTContext.runActivity(named: "Ungroup tokens") { _ in
            groupButton.waitAndTap()

            // Wait for ungrouping to take effect
            waitForGroupingState(expectedGrouped: false)
            return self
        }
    }

    func isGrouped() -> Bool {
        // Check group button title
        let groupButtonTitle = groupButton.label.lowercased()
        if groupButtonTitle.contains("ungroup") {
            return true
        }
        if groupButtonTitle.contains("group") {
            return false
        }

        // Check group headers
        let networkHeaders = tokensList.descendants(matching: .staticText)
            .allElementsBoundByIndex
            .filter { element in
                let text = element.label.lowercased()
                return text.hasSuffix("network")
            }

        if !networkHeaders.isEmpty {
            return true
        }

        // Check section drag buttons
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
            getTokenDragIcon(name: source).press(forDuration: 1.0, thenDragTo: getTokenDragIcon(name: destination))
            return self
        }
    }

    @discardableResult
    func dragToken(fromName: String, toName: String) -> Self {
        XCTContext.runActivity(named: "Drag token from '\(fromName)' to '\(toName)'") { _ in
            let sourceIcon = getTokenDragIcon(name: fromName)
            let destinationIcon = getTokenDragIcon(name: toName)

            XCTAssertTrue(sourceIcon.exists, "Source drag icon should exist for token: \(fromName)")
            XCTAssertTrue(destinationIcon.exists, "Destination drag icon should exist for token: \(toName)")

            // Perform drag & drop
            sourceIcon.press(forDuration: 1.0, thenDragTo: destinationIcon)
            return self
        }
    }

    func getTokensOrder() -> [String] {
        // Get all elements with token identifiers
        let allElements = tokensList.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'token_' AND identifier CONTAINS '_'"))
            .allElementsBoundByIndex

        // Group elements by identifier and take only unique ones
        var uniqueTokens: [String: XCUIElement] = [:]

        for element in allElements {
            let identifier = element.identifier
            if !uniqueTokens.keys.contains(identifier), element.exists, element.frame.width > 0 {
                uniqueTokens[identifier] = element
            }
        }

        // Parse identifier to get position and name
        let tokenInfo: [(section: Int, item: Int, name: String)] = uniqueTokens.compactMap { identifier, element in
            let components = identifier.components(separatedBy: "_")

            // Expected format: token_section_item_name
            guard components.count >= 4,
                  components[0] == "token",
                  let section = Int(components[1]),
                  let item = Int(components[2]) else {
                return nil
            }

            let name = components[3...].joined(separator: "_")
            return (section: section, item: item, name: name)
        }

        // Sort by position (section, then item)
        let sortedTokens = tokenInfo.sorted { first, second in
            if first.section != second.section {
                return first.section < second.section
            }
            return first.item < second.item
        }

        return sortedTokens.map { $0.name }
    }

    @discardableResult
    func verifyTokensOrder(_ expectedOrder: [String]) -> Self {
        XCTContext.runActivity(named: "Verify tokens order matches expected") { _ in
            let actualOrder = getTokensOrder()
            XCTAssertEqual(actualOrder, expectedOrder, "Tokens order doesn't match expected")
            return self
        }
    }

    private func getTokenDragIcon(name: String) -> XCUIElement {
        // Find elements with label from Assets and filter by token name in identifier
        return app.images
            .matching(NSPredicate(format: "label == %@ AND identifier CONTAINS %@", Assets.OrganizeTokens.itemDragAndDropIcon.name, name))
            .firstMatch
    }

    private func isGroupingButtonShowingUngroup() -> Bool {
        let buttonTitle = groupButton.label.lowercased()
        return buttonTitle.contains("ungroup")
    }

    private func waitForGroupingState(expectedGrouped: Bool, timeout: TimeInterval = 5.0) {
        // Wait for the group button to show the expected state
        let expectedButtonText = expectedGrouped ? "Ungroup" : "Group"
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedButtonText)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: groupButton)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Timed out waiting for group button to show '\(expectedButtonText)'")
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
