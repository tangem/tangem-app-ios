//
//  EarnCalculatorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("EarnCalculatorViewModel")
@MainActor
final class EarnCalculatorViewModelTests: LeakTrackingTestSuite {
    // MARK: - Initial State

    @Test("Builds one bar per sampled point, capped at 24")
    func capsBarCount() {
        let (sut, _) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears))

        #expect(sut.state.bars.count == 24)
    }

    @Test("Builds one bar per month when the horizon is shorter than the cap")
    func barPerMonthForShortHorizon() {
        let (sut, _) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: .sixMonths))

        #expect(sut.state.bars.count == 6)
    }

    @Test("Normalizes bar heights against the tallest bar")
    func normalizesBarHeights() throws {
        let (sut, _) = makeSUT()

        let heights = sut.state.bars.map(\.normalizedHeight)

        #expect(try #require(heights.last) == 1)
        #expect(heights.allSatisfy { (0 ... 1).contains($0) })
        #expect(heights == heights.sorted())
    }

    @Test("Ends the chart on the projected total")
    func lastBarMatchesTotal() throws {
        let (sut, _) = makeSUT()

        #expect(try #require(sut.state.bars.last).balance == sut.state.totalBalance)
    }

    @Test("Prefixes positive earnings with a plus sign only")
    func earnedSign() {
        let (positive, _) = makeSUT(projector: EarnCalculatorProjectorSpy(earnedPerMonth: 1))
        let (negative, _) = makeSUT(projector: EarnCalculatorProjectorSpy(earnedPerMonth: -1))

        #expect(positive.state.earned.hasPrefix("+"))
        #expect(!negative.state.earned.hasPrefix("+"))
    }

    @Test("Omits the plus sign when earnings round to zero")
    func earnedRoundingToZero() throws {
        let (sut, _) = makeSUT(projector: EarnCalculatorProjectorSpy(earnedPerMonth: 0.3))

        let firstBar = try #require(sut.state.bars.first)

        #expect(!firstBar.earned.hasPrefix("+"))
        #expect(sut.state.earned.hasPrefix("+"))
    }

    @Test("Hides the incentive badge without an incentive APY")
    func hidesIncentiveBadge() {
        let (sut, _) = makeSUT(incentiveApy: nil)

        #expect(sut.state.incentiveBadgeText == nil)
    }

    @Test("Shows the incentive badge with an incentive APY")
    func showsIncentiveBadge() {
        let (sut, _) = makeSUT(incentiveApy: 0.014)

        #expect(sut.state.incentiveBadgeText != nil)
    }

    // MARK: - Inputs

    @Test("Increases a field by its step")
    func increasesByStep() throws {
        let (sut, spy) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears))
        let valuesBefore = sut.state.inputs.map(\.value)

        sut.increase(.initialBalance)
        sut.increase(.monthlyTopUp)

        let input = try #require(spy.inputs.last)
        #expect(input.initialBalance == 2500 + EarnCalculatorField.initialBalance.step)
        #expect(input.monthlyTopUp == 500 + EarnCalculatorField.monthlyTopUp.step)
        #expect(zip(valuesBefore, sut.state.inputs.map(\.value)).allSatisfy { $0 != $1 })
    }

    @Test("Does not go below the lower bound and disables decrease there")
    func clampsAtLowerBound() throws {
        let (sut, spy) = makeSUT(input: .init(initialBalance: 0, monthlyTopUp: 0, horizon: .threeYears))
        let callsBefore = spy.inputs.count

        sut.decrease(.initialBalance)

        #expect(spy.inputs.count == callsBefore)
        let input = try #require(sut.state.inputs.first { $0.field == .initialBalance })
        #expect(!input.canDecrease)
        #expect(input.canIncrease)
    }

    @Test("Clamps to the upper bound and disables increase there")
    func clampsAtUpperBound() throws {
        let upperBound = EarnCalculatorField.initialBalance.range.upperBound
        let (sut, spy) = makeSUT(input: .init(initialBalance: upperBound - 1, monthlyTopUp: 0, horizon: .threeYears))

        sut.increase(.initialBalance)

        #expect(try #require(spy.inputs.last).initialBalance == upperBound)
        let input = try #require(sut.state.inputs.first { $0.field == .initialBalance })
        #expect(!input.canIncrease)
    }

    // MARK: - Horizon

    @Test("Switches the horizon and recomputes the projection")
    func switchesHorizon() throws {
        let (sut, spy) = makeSUT()

        sut.select(horizon: .tenYears)

        #expect(sut.selectedHorizon == .tenYears)
        #expect(try #require(spy.inputs.last).horizon == .tenYears)
        #expect(sut.state.bars.compactMap(\.axisLabel) == EarnCalculatorHorizon.tenYears.axisTicks.map(\.label))
    }

    @Test("Puts each axis label under the bar of its month", arguments: EarnCalculatorHorizon.allCases)
    func axisLabelsMatchBarMonths(horizon: EarnCalculatorHorizon) throws {
        let (sut, _) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: horizon))
        let barMonths = sut.state.bars.map(\.month)

        for tick in horizon.axisTicks {
            let bar = try #require(sut.state.bars.first { $0.axisLabel == tick.label })
            let nearestDistance = try #require(barMonths.map { abs($0 - tick.month) }.min())
            #expect(abs(bar.month - tick.month) == nearestDistance)
        }
    }

    @Test("Labels the three-year chart at months 12, 24 and 36")
    func threeYearTicksLandOnExactMonths() {
        let (sut, _) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears))

        let labelledMonths = sut.state.bars.filter { $0.axisLabel != nil }.map(\.month)

        #expect(labelledMonths == [12, 24, 36])
    }

    @Test("Ignores selecting the current horizon")
    func ignoresSameHorizon() {
        let (sut, spy) = makeSUT(input: .init(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears))
        let callsBefore = spy.inputs.count

        sut.select(horizon: .threeYears)

        #expect(spy.inputs.count == callsBefore)
    }

    // MARK: - Bar Selection

    @Test("Resets the selected bar when the projection changes")
    func resetsSelectedBar() {
        let (sut, _) = makeSUT()
        sut.selectedBarID = 5

        sut.increase(.monthlyTopUp)

        #expect(sut.selectedBarID == nil)
    }

    @Test("Keeps the selected bar when nothing changes")
    func keepsSelectedBar() {
        let (sut, _) = makeSUT(input: .init(initialBalance: 0, monthlyTopUp: 0, horizon: .threeYears))
        sut.selectedBarID = 5

        sut.decrease(.monthlyTopUp)

        #expect(sut.selectedBarID == 5)
    }
}

// MARK: - Helpers

private extension EarnCalculatorViewModelTests {
    func makeSUT(
        input: EarnCalculatorInput = .default,
        incentiveApy: Decimal? = nil,
        projector: EarnCalculatorProjectorSpy = EarnCalculatorProjectorSpy()
    ) -> (sut: EarnCalculatorViewModel, spy: EarnCalculatorProjectorSpy) {
        let sut = EarnCalculatorViewModel(
            input: input,
            incentiveApy: incentiveApy,
            projector: projector,
            currencyCode: "USD"
        )

        return (trackForMemoryLeaks(sut), projector)
    }
}

private final class EarnCalculatorProjectorSpy: EarnCalculatorProjecting {
    private(set) var inputs: [EarnCalculatorInput] = []

    private let earnedPerMonth: Decimal

    init(earnedPerMonth: Decimal = 1) {
        self.earnedPerMonth = earnedPerMonth
    }

    func project(_ input: EarnCalculatorInput) -> EarnCalculatorProjection {
        inputs.append(input)

        let points = (1 ... input.horizon.months).map { month in
            let earned = earnedPerMonth * Decimal(month)

            return EarnCalculatorProjection.Point(
                month: month,
                balance: input.initialBalance + input.monthlyTopUp * Decimal(month) + earned,
                earned: earned
            )
        }

        return EarnCalculatorProjection(points: points)
    }
}
