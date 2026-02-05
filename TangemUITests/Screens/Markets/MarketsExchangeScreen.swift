//
//  MarketsExchangeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsExchangeScreen: ScreenBase<MarketsExchangeScreenElement> {
    private lazy var exchangesListTitle = staticText(.exchangesListTitle)
    private lazy var exchangeName = staticText(.exchangeName)
    private lazy var exchangeLogo = image(.exchangeLogo)
    private lazy var tradingVolume = staticText(.tradingVolume)
    private lazy var exchangeType = staticText(.exchangeType)
    private lazy var trustScore = staticText(.trustScore)
    private lazy var tryAgainButton = button(.tryAgainButton)

    @discardableResult
    func verifyExchangesListScreen() -> Self {
        XCTContext.runActivity(named: "Verify Markets Exchange List Screen") { _ in
            waitAndAssertTrue(exchangesListTitle, "Exchanges list title should exist")
            waitAndAssertTrue(exchangeName.firstMatch, "Exchange name should exist")
            waitAndAssertTrue(exchangeLogo.firstMatch, "Exchange logo should exist")
            waitAndAssertTrue(tradingVolume.firstMatch, "Trading volume should exist")
            waitAndAssertTrue(exchangeType.firstMatch, "Exchange type should exist")
            waitAndAssertTrue(trustScore.firstMatch, "Trust score should exist")

            return self
        }
    }

    func getTradingVolumes() -> [Decimal] {
        XCTContext.runActivity(named: "Get trading volumes from list") { _ in
            waitAndAssertTrue(tradingVolume.firstMatch)
            let volumeElements = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.exchangesListTradingVolume
            ).allElementsBoundByIndex
            return volumeElements.map { NumericValueHelper.parseNumericValue(from: $0.label) }
        }
    }

    @discardableResult
    func verifyExchangesListSortedByVolume() -> Self {
        XCTContext.runActivity(named: "Verify exchanges list is sorted by volume (descending)") {
            _ in
            let volumes = getTradingVolumes()
            XCTAssertFalse(volumes.isEmpty, "Trading volumes list should not be empty")
            let sortedVolumes = volumes.sorted(by: >)
            XCTAssertEqual(
                volumes, sortedVolumes,
                "Exchanges list should be sorted by volume in descending order"
            )
            return self
        }
    }

    @discardableResult
    func verifyExchangeTypes() -> Self {
        XCTContext.runActivity(named: "Verify exchanges list types") { _ in
            let typesQuery = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.exchangesListType
            )
            waitAndAssertTrue(typesQuery.firstMatch, "Exchange type should exist")

            let types = typesQuery.allElementsBoundByIndex
            XCTAssertFalse(types.isEmpty, "Exchange types list should not be empty")

            for type in types {
                let label = type.label
                XCTAssertTrue(
                    label == "CEX" || label == "DEX",
                    "Exchange type should be CEX or DEX, but found: \(label)"
                )
            }
            return self
        }
    }

    @discardableResult
    func verifyExchangeTrustScore() -> Self {
        XCTContext.runActivity(named: "Verify exchanges trust scores") { _ in
            waitAndAssertTrue(
                app.staticTexts[MarketsAccessibilityIdentifiers.exchangesListTrustScore].firstMatch,
                "Trust scores should exist"
            )

            let scores = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.exchangesListTrustScore
            ).allElementsBoundByIndex

            XCTAssertFalse(scores.isEmpty, "Trust scores list should not be empty")

            let validScores = ["Risky", "Caution", "Trusted"]

            for score in scores {
                let label = score.label
                XCTAssertTrue(
                    validScores.contains(label),
                    "Trust score should be one of \(validScores), but found: \(label)"
                )
            }
            return self
        }
    }

    @discardableResult
    func verifyUnableToLoadData() -> Self {
        XCTContext.runActivity(named: "Verify unable to load data state") { _ in
            waitAndAssertTrue(tryAgainButton, "Try again button should exist")
            return self
        }
    }

    @discardableResult
    func tapTryAgain() -> Self {
        XCTContext.runActivity(named: "Tap 'Try again' button") { _ in
            tryAgainButton.tap()
            return self
        }
    }
}

enum MarketsExchangeScreenElement: String, UIElement {
    case exchangesListTitle
    case exchangeName
    case exchangeLogo
    case tradingVolume
    case exchangeType
    case trustScore
    case tryAgainButton

    var accessibilityIdentifier: String {
        switch self {
        case .exchangesListTitle:
            MarketsAccessibilityIdentifiers.exchangesListTitle
        case .exchangeName:
            MarketsAccessibilityIdentifiers.exchangesListExchangeName
        case .exchangeLogo:
            MarketsAccessibilityIdentifiers.exchangesListExchangeLogo
        case .tradingVolume:
            MarketsAccessibilityIdentifiers.exchangesListTradingVolume
        case .exchangeType:
            MarketsAccessibilityIdentifiers.exchangesListType
        case .trustScore:
            MarketsAccessibilityIdentifiers.exchangesListTrustScore
        case .tryAgainButton:
            CommonUIAccessibilityIdentifiers.retryButton
        }
    }
}
