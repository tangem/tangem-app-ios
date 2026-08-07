//
//  TokenDetailsMarketPriceScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TokenDetailsMarketPriceScreen: ScreenBase<TokenDetailsMarketPriceElement> {
    private lazy var block = anyElement(.block)
    private lazy var title = anyElement(.title)
    private lazy var price = anyElement(.price)
    private lazy var priceChange = anyElement(.priceChange)
    private lazy var chart = anyElement(.chart)

    @discardableResult
    func waitForBlock() -> Self {
        XCTContext.runActivity(named: "Wait for Market Price block") { _ in
            scrollToElement(block)
            waitAndAssertTrue(block, "Market Price block should be displayed")
        }
        return self
    }

    @discardableResult
    func validateBlockData() -> Self {
        XCTContext.runActivity(named: "Validate Market Price block data") { _ in
            waitAndAssertTrue(title, "Market Price title should be displayed")
            XCTAssertFalse(title.label.isEmpty, "Market Price title should not be empty")
            waitAndAssertTrue(price, "Market Price price should be displayed")
            waitAndAssertTrue(priceChange, "Market Price 24h change should be displayed")
            waitAndAssertTrue(chart, "Market Price mini chart should be displayed")
        }
        return self
    }

    private func anyElement(_ element: TokenDetailsMarketPriceElement) -> XCUIElement {
        app.descendants(matching: .any)[element.accessibilityIdentifier].firstMatch
    }
}

enum TokenDetailsMarketPriceElement: String, UIElement {
    case block
    case title
    case price
    case priceChange
    case chart

    var accessibilityIdentifier: String {
        switch self {
        case .block:
            return TokenAccessibilityIdentifiers.marketPriceBlock
        case .title:
            return TokenAccessibilityIdentifiers.marketPriceTitle
        case .price:
            return TokenAccessibilityIdentifiers.marketPricePrice
        case .priceChange:
            return TokenAccessibilityIdentifiers.marketPricePriceChange
        case .chart:
            return TokenAccessibilityIdentifiers.marketPriceChart
        }
    }
}
