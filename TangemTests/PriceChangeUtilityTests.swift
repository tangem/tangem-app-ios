//
//  PriceChangeUtilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import Testing
@testable import Tangem

class PriceChangeUtilityTests: XCTestCase {
    private let utility = PriceChangeUtility()

    // MARK: - convertToPriceChangeState(changeFractional:)

    func testFractionalNilReturnsNoData() {
        let state = utility.convertToPriceChangeState(changeFractional: nil)
        XCTAssertEqual(state, .noData)
    }

    func testFractionalPositiveReturnsLoadedPositive() throws {
        let fractional = try #require(Decimal(stringValue: "0.05"))
        let state = utility.convertToPriceChangeState(changeFractional: fractional)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testFractionalNegativeReturnsLoadedNegative() throws {
        let fractional = try #require(Decimal(stringValue: "-0.05"))
        let state = utility.convertToPriceChangeState(changeFractional: fractional)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testFractionalZeroReturnsLoadedNeutral() throws {
        let fractional = try #require(Decimal(stringValue: "0"))
        let state = utility.convertToPriceChangeState(changeFractional: fractional)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testFractionalVerySmallPositiveRoundsToNeutral() throws {
        // 0.00000001 rounds to 0.00% → neutral
        let fractional = try #require(Decimal(stringValue: "0.00000001"))
        let state = utility.convertToPriceChangeState(changeFractional: fractional)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testFractionalVerySmallNegativeRoundsToNeutral() throws {
        let fractional = try #require(Decimal(stringValue: "-0.00000001"))
        let state = utility.convertToPriceChangeState(changeFractional: fractional)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    // MARK: - convertToPriceChangeState(changePercent:changeValue:loading:)

    func testPercentNilReturnsNoData() {
        let state = utility.convertToPriceChangeState(changePercent: nil)
        XCTAssertEqual(state, .noData)
    }

    func testPercentNilWithLoadingReturnsNoData() {
        let state = utility.convertToPriceChangeState(changePercent: nil, loading: true)
        XCTAssertEqual(state, .noData)
    }

    func testPercentPositiveReturnsLoadedPositive() throws {
        let percent = try #require(Decimal(stringValue: "5.0"))
        let state = utility.convertToPriceChangeState(changePercent: percent)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPercentNegativeReturnsLoadedNegative() throws {
        let percent = try #require(Decimal(stringValue: "-5.0"))
        let state = utility.convertToPriceChangeState(changePercent: percent)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testPercentZeroReturnsLoadedNeutral() throws {
        let percent = try #require(Decimal(stringValue: "0"))
        let state = utility.convertToPriceChangeState(changePercent: percent)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testPercentWithLoadingTrueReturnsLoadingCached() throws {
        let percent = try #require(Decimal(stringValue: "5.0"))
        let state = utility.convertToPriceChangeState(changePercent: percent, loading: true)
        guard case .loadingCached(let changeType, _) = state else {
            return XCTFail("Expected .loadingCached, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    // MARK: - calculatePriceChangeStateBetween

    func testPriceIncreasedReturnsPositive() throws {
        let currentPrice = try #require(Decimal(stringValue: "110.0"))
        let previousPrice = try #require(Decimal(stringValue: "100.0"))
        // (110 - 100) / 100 * 100 = +10%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: currentPrice, previousPrice: previousPrice)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPriceDecreasedReturnsNegative() throws {
        let currentPrice = try #require(Decimal(stringValue: "90.0"))
        let previousPrice = try #require(Decimal(stringValue: "100.0"))
        // (90 - 100) / 100 * 100 = -10%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: currentPrice, previousPrice: previousPrice)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testPriceUnchangedReturnsNeutral() throws {
        let currentPrice = try #require(Decimal(stringValue: "100.0"))
        let previousPrice = try #require(Decimal(stringValue: "100.0"))
        let state = utility.calculatePriceChangeStateBetween(currentPrice: currentPrice, previousPrice: previousPrice)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testPriceDoubledReturnsPositive() throws {
        let currentPrice = try #require(Decimal(stringValue: "200.0"))
        let previousPrice = try #require(Decimal(stringValue: "100.0"))
        // (200 - 100) / 100 * 100 = +100%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: currentPrice, previousPrice: previousPrice)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPriceDroppedByHalfReturnsNegative() throws {
        let currentPrice = try #require(Decimal(stringValue: "50.0"))
        let previousPrice = try #require(Decimal(stringValue: "100.0"))
        // (50 - 100) / 100 * 100 = -50%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: currentPrice, previousPrice: previousPrice)
        guard case .loaded(let changeType, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }
}
