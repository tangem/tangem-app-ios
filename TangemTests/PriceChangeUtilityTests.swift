//
//  PriceChangeUtilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class PriceChangeUtilityTests: XCTestCase {
    private let utility = PriceChangeUtility()

    // MARK: - convertToPriceChangeState(changeFractional:)

    func testFractionalNilReturnsNoData() {
        let state = utility.convertToPriceChangeState(changeFractional: nil)
        XCTAssertEqual(state, .noData)
    }

    func testFractionalPositiveReturnsLoadedPositive() {
        let state = utility.convertToPriceChangeState(changeFractional: 0.05)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testFractionalNegativeReturnsLoadedNegative() {
        let state = utility.convertToPriceChangeState(changeFractional: -0.05)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testFractionalZeroReturnsLoadedNeutral() {
        let state = utility.convertToPriceChangeState(changeFractional: 0)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testFractionalVerySmallPositiveRoundsToNeutral() {
        // 0.00000001 rounds to 0.00% → neutral
        let state = utility.convertToPriceChangeState(changeFractional: 0.00000001)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testFractionalVerySmallNegativeRoundsToNeutral() {
        let state = utility.convertToPriceChangeState(changeFractional: -0.00000001)
        guard case .loaded(let changeType, _, _) = state else {
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

    func testPercentPositiveReturnsLoadedPositive() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPercentNegativeReturnsLoadedNegative() {
        let state = utility.convertToPriceChangeState(changePercent: -5.0)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testPercentZeroReturnsLoadedNeutral() {
        let state = utility.convertToPriceChangeState(changePercent: 0)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testPercentWithLoadingTrueReturnsLoadingCached() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0, loading: true)
        guard case .loadingCached(let changeType, _, _) = state else {
            return XCTFail("Expected .loadingCached, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPercentWithoutChangeValueHasNoSubtext() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0)
        guard case .loaded(_, _, let subtext) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertNil(subtext)
    }

    func testPercentWithChangeValueHasSubtext() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0, changeValue: 100.0)
        guard case .loaded(_, _, let subtext) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertNotNil(subtext)
    }

    func testPercentWithLoadingAndChangeValueReturnsLoadingCachedWithSubtext() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0, changeValue: 50.0, loading: true)
        guard case .loadingCached(_, _, let subtext) = state else {
            return XCTFail("Expected .loadingCached, got \(state)")
        }
        XCTAssertNotNil(subtext)
    }

    func testPercentWithLoadingAndNoChangeValueReturnsLoadingCachedWithNoSubtext() {
        let state = utility.convertToPriceChangeState(changePercent: 5.0, loading: true)
        guard case .loadingCached(_, _, let subtext) = state else {
            return XCTFail("Expected .loadingCached, got \(state)")
        }
        XCTAssertNil(subtext)
    }

    // MARK: - calculatePriceChangeStateBetween

    func testPriceIncreasedReturnsPositive() {
        // (110 - 100) / 100 * 100 = +10%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: 110, previousPrice: 100)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPriceDecreasedReturnsNegative() {
        // (90 - 100) / 100 * 100 = -10%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: 90, previousPrice: 100)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }

    func testPriceUnchangedReturnsNeutral() {
        let state = utility.calculatePriceChangeStateBetween(currentPrice: 100, previousPrice: 100)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .neutral)
    }

    func testPriceDoubledReturnsPositive() {
        // (200 - 100) / 100 * 100 = +100%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: 200, previousPrice: 100)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .positive)
    }

    func testPriceDroppedByHalfReturnsNegative() {
        // (50 - 100) / 100 * 100 = -50%
        let state = utility.calculatePriceChangeStateBetween(currentPrice: 50, previousPrice: 100)
        guard case .loaded(let changeType, _, _) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(changeType, .negative)
    }
}
