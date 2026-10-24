//
//  TangemPayCashbackScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCashbackScreen: ScreenBase<TangemPayCashbackScreenElement> {
    private lazy var closeButton = button(.closeButton)
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var headerSubtitle = staticText(.headerSubtitle)
    private lazy var infoBanner = staticText(.infoBanner)
    private lazy var rateCard = button(.rateCard)
    private lazy var accrualsCard = button(.accrualsCard)
    private lazy var chartTotal = staticText(.chartTotal)
    private lazy var additionalSectionTitle = staticText(.additionalSectionTitle)
    private lazy var errorTitle = staticText(.errorTitle)
    private lazy var reloadButton = button(.reloadButton)
    private lazy var chartMonthLabels = app.staticTexts
        .matching(NSPredicate(format: "identifier BEGINSWITH %@", TangemPayAccessibilityIdentifiers.cashbackChartMonthPrefix))

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Cashback screen") { _ in
            waitAndAssertTrue(closeButton, "Cashback screen should be opened")
            return self
        }
    }

    func isOpened(timeout: TimeInterval) -> Bool {
        closeButton.waitForExistence(timeout: timeout)
    }

    @discardableResult
    func verifyEarnedHeader(amount: String, month: String) -> Self {
        XCTContext.runActivity(named: "Verify the header shows '\(amount) earned in \(month)'") { _ in
            waitAndAssertTrue(headerTitle, timeout: .networkRequest, "Cashback screen header should be displayed")
            XCTAssertEqual(headerTitle.label, Localization.tangempayCashbackEarnedTitle(amount, month), "Header should show the month accruals")
            return self
        }
    }

    @discardableResult
    func verifyEmptyHeader() -> Self {
        XCTContext.runActivity(named: "Verify the empty state header") { _ in
            waitAndAssertTrue(headerTitle, timeout: .networkRequest, "Cashback screen header should be displayed")
            XCTAssertEqual(
                headerTitle.label.singleLine,
                Localization.tangempayCashbackEmptyTitle.singleLine,
                "Empty header should invite to start spending and earn cashback"
            )
            XCTAssertEqual(headerSubtitle.label, Localization.tangempayCashbackEmptySubtitle, "Empty header subtitle mismatch")
            return self
        }
    }

    @discardableResult
    func verifyPayoutWindow(_ window: String) -> Self {
        XCTContext.runActivity(named: "Verify the payout window '\(window)'") { _ in
            waitAndAssertTrue(headerSubtitle, "Payout window should be displayed")
            XCTAssertEqual(headerSubtitle.label, Localization.tangempayCashbackDepositedOn(window), "Payout window mismatch")
            return self
        }
    }

    @discardableResult
    func verifyPayoutWindowHidden() -> Self {
        XCTContext.runActivity(named: "Verify the payout window is hidden") { _ in
            waitAndAssertTrue(headerTitle, timeout: .networkRequest, "Cashback screen header should be displayed")
            XCTAssertFalse(headerSubtitle.exists, "Payout window should not be displayed")
            return self
        }
    }

    @discardableResult
    func verifyRefundBanner() -> Self {
        XCTContext.runActivity(named: "Verify the refund banner") { _ in
            waitAndAssertTrue(infoBanner, "Refund banner should be displayed")
            XCTAssertEqual(infoBanner.label, Localization.tangempayCashbackRefundBanner, "Refund banner text mismatch")
            return self
        }
    }

    @discardableResult
    func verifyDepositBanner(amount: String, month: String, payoutDate: String) -> Self {
        XCTContext.runActivity(named: "Verify the payout banner for \(month)") { _ in
            waitAndAssertTrue(infoBanner, "Payout banner should be displayed")
            XCTAssertEqual(
                infoBanner.label,
                Localization.tangempayCashbackDepositBanner(amount, month, payoutDate),
                "Payout banner text mismatch"
            )
            return self
        }
    }

    @discardableResult
    func verifyRateCard(rate: String, plan: String) -> Self {
        XCTContext.runActivity(named: "Verify the cashback rate card") { _ in
            waitAndAssertTrue(rateCard, "Cashback rate card should be displayed")
            XCTAssertTrue(
                rateCard.label.contains(Localization.tangempayCashbackRateTitle(rate)),
                "Rate card should show the rate, got '\(rateCard.label)'"
            )
            XCTAssertTrue(
                rateCard.label.contains(Localization.tangempayCashbackRateSubtitle(plan)),
                "Rate card should show the plan, got '\(rateCard.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyAccrualsCard() -> Self {
        XCTContext.runActivity(named: "Verify the Accruals card") { _ in
            waitAndAssertTrue(accrualsCard, "Accruals card should be displayed")
            XCTAssertTrue(
                accrualsCard.label.contains(Localization.tangempayCashbackAccrualsTitle),
                "Accruals card title mismatch, got '\(accrualsCard.label)'"
            )
            XCTAssertTrue(
                accrualsCard.label.contains(Localization.tangempayCashbackAccrualsSubtitle),
                "Accruals card subtitle mismatch, got '\(accrualsCard.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyChartTotal(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Verify the chart title '\(amount) earned in total'") { _ in
            scrollToElement(chartTotal)
            waitAndAssertTrue(chartTotal, "Chart title should be displayed")
            XCTAssertEqual(chartTotal.label, Localization.tangempayCashbackTotalEarned(amount), "Chart title mismatch")
            return self
        }
    }

    @discardableResult
    func verifyChartMonths(_ months: [String]) -> Self {
        XCTContext.runActivity(named: "Verify the chart columns \(months.joined(separator: ", "))") { _ in
            let labels = months.map { app.staticTexts[TangemPayAccessibilityIdentifiers.cashbackChartMonth($0)].firstMatch }
            labels.forEach { scrollToElement($0) }
            zip(months, labels).forEach { month, label in
                waitAndAssertTrue(label, "Chart column for \(month) should be displayed")
            }
            XCTAssertEqual(chartMonthLabels.count, months.count, "Chart should have \(months.count) columns")
            let positions = labels.map(\.frame.minX)
            XCTAssertEqual(positions, positions.sorted(), "Chart columns should go from \(months.first ?? "") to \(months.last ?? "")")
            return self
        }
    }

    @discardableResult
    func verifyChartValue(_ value: String, month: String) -> Self {
        XCTContext.runActivity(named: "Verify the \(month) column shows \(value)") { _ in
            let valueLabel = app.staticTexts[TangemPayAccessibilityIdentifiers.cashbackChartValue(month)].firstMatch
            scrollToElement(valueLabel)
            waitAndAssertTrue(valueLabel, "\(month) column value should be displayed")
            XCTAssertEqual(valueLabel.label, value, "\(month) column value mismatch")
            return self
        }
    }

    @discardableResult
    func verifyAdditionalCashbackSection() -> Self {
        XCTContext.runActivity(named: "Verify the Additional cashback section") { _ in
            scrollToElement(additionalSectionTitle)
            waitAndAssertTrue(additionalSectionTitle, "Additional cashback section should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyFailedState() -> Self {
        XCTContext.runActivity(named: "Verify the Cashback screen failure state") { _ in
            waitAndAssertTrue(errorTitle, timeout: .networkRequest, "Failure message should be displayed")
            XCTAssertEqual(errorTitle.label.singleLine, Localization.tangempayCashbackErrorTitle.singleLine, "Failure message mismatch")
            waitAndAssertTrue(reloadButton, "Reload button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapReload() -> Self {
        XCTContext.runActivity(named: "Tap Reload on the Cashback screen") { _ in
            reloadButton.waitAndTap()
            return self
        }
    }
}

enum TangemPayCashbackScreenElement: String, UIElement {
    case closeButton
    case headerTitle
    case headerSubtitle
    case infoBanner
    case rateCard
    case accrualsCard
    case chartTotal
    case additionalSectionTitle
    case errorTitle
    case reloadButton

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            TangemPayAccessibilityIdentifiers.cashbackDetailCloseButton
        case .headerTitle:
            TangemPayAccessibilityIdentifiers.cashbackDetailHeaderTitle
        case .headerSubtitle:
            TangemPayAccessibilityIdentifiers.cashbackDetailHeaderSubtitle
        case .infoBanner:
            TangemPayAccessibilityIdentifiers.cashbackDetailInfoBanner
        case .rateCard:
            TangemPayAccessibilityIdentifiers.cashbackDetailRateCard
        case .accrualsCard:
            TangemPayAccessibilityIdentifiers.cashbackDetailAccrualsCard
        case .chartTotal:
            TangemPayAccessibilityIdentifiers.cashbackChartTotal
        case .additionalSectionTitle:
            TangemPayAccessibilityIdentifiers.cashbackAdditionalSectionTitle
        case .errorTitle:
            TangemPayAccessibilityIdentifiers.cashbackDetailErrorTitle
        case .reloadButton:
            TangemPayAccessibilityIdentifiers.cashbackDetailReloadButton
        }
    }
}

private extension String {
    var singleLine: String {
        replacingOccurrences(of: "\n", with: " ")
    }
}
