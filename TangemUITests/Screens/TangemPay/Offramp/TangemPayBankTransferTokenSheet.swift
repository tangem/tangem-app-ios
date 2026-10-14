//
//  TangemPayBankTransferTokenSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferTokenSheet: Screen {
    let app: XCUIApplication

    private lazy var rows = app.buttons.matching(identifier: TangemPayOfframpAccessibilityIdentifiers.tokenSheetRow)
    private lazy var title = app.staticTexts[Localization.commonChooseNetwork].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the Choose network sheet") { _ in
            waitAndAssertTrue(title, "Choose network sheet should be displayed")
            waitAndAssertTrue(rows.firstMatch, "Choose network sheet should list tokens")
            return self
        }
    }

    @discardableResult
    func verifyAvailableToken(symbol: String, network: TangemPayNetwork, balance: String, isSelected: Bool) -> Self {
        XCTContext.runActivity(named: "Verify \(symbol) on \(network.displayName) shows \(balance)") { _ in
            let row = self.row(symbol: symbol, network: network)
            waitAndAssertTrue(row, "\(symbol) on \(network.displayName) should be listed")
            XCTAssertTrue(
                row.label.contains(Localization.tangempayWithdrawBankSourceSubtitle(network.displayName, balance)),
                "\(symbol) on \(network.displayName) should show '\(balance)'. Actual: '\(row.label)'"
            )
            XCTAssertTrue(row.isEnabled, "\(symbol) on \(network.displayName) should be selectable")
            XCTAssertEqual(
                row.isSelected,
                isSelected,
                "\(symbol) on \(network.displayName) should\(isSelected ? "" : " not") carry the checkmark"
            )
            return self
        }
    }

    @discardableResult
    func verifyUnavailableToken(symbol: String, network: TangemPayNetwork) -> Self {
        XCTContext.runActivity(named: "Verify \(symbol) on \(network.displayName) is unavailable for off-ramp") { _ in
            let row = self.row(symbol: symbol, network: network)
            waitAndAssertTrue(row, "\(symbol) on \(network.displayName) should be listed")
            let subtitle = Localization.tangempayWithdrawBankSourceSubtitle(network.displayName, Localization.tangempayWithdrawBankOfframpUnavailable)
            XCTAssertTrue(
                row.label.contains(subtitle),
                "\(symbol) on \(network.displayName) should read '\(subtitle)'. Actual: '\(row.label)'"
            )
            XCTAssertFalse(row.isEnabled, "\(symbol) on \(network.displayName) should not be selectable")
            return self
        }
    }

    @discardableResult
    func verifyTokenCount(_ count: Int) -> Self {
        XCTContext.runActivity(named: "Verify the sheet lists \(count) tokens") { _ in
            XCTAssertEqual(rows.count, count, "Choose network should list \(count) tokens")
            return self
        }
    }

    @discardableResult
    func selectToken(symbol: String, network: TangemPayNetwork) -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Select \(symbol) on \(network.displayName)") { _ in
            row(symbol: symbol, network: network).waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .conditional), "Choose network sheet should close after the selection")
            return TangemPayBankTransferAmountScreen(app)
        }
    }

    @discardableResult
    func close() -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Close the Choose network sheet") { _ in
            let sheetTop = title.frame.minY - Constants.headerHeight
            let closeButton = app.buttons
                .matching(NSPredicate(format: "label == %@", Localization.commonClose))
                .allElementsBoundByIndex
                .first { $0.isHittable && $0.frame.minY >= sheetTop }
            guard let closeButton else {
                XCTFail("Choose network sheet Close button should be hittable")
                return TangemPayBankTransferAmountScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .conditional), "Choose network sheet should be dismissed")
            return TangemPayBankTransferAmountScreen(app)
        }
    }

    private func row(symbol: String, network: TangemPayNetwork) -> XCUIElement {
        rows.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", symbol, network.displayName)).firstMatch
    }
}

private extension TangemPayBankTransferTokenSheet {
    enum Constants {
        static let headerHeight: CGFloat = 44
    }
}
