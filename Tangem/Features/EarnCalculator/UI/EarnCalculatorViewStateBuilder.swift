//
//  EarnCalculatorViewStateBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

struct EarnCalculatorViewStateBuilder {
    private let currencyCode: String
    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()

    init(currencyCode: String) {
        self.currencyCode = currencyCode
    }

    func build(
        input: EarnCalculatorInput,
        projection: EarnCalculatorProjection,
        incentiveApy: Decimal?
    ) -> EarnCalculatorViewState {
        EarnCalculatorViewState(
            incentiveBadgeText: incentiveApy.map(makeIncentiveBadgeText),
            totalBalance: balanceFormatter.formatFiatBalance(projection.finalBalance, currencyCode: currencyCode),
            earned: formatEarned(projection.earned),
            horizonTitle: input.horizon.inlineTitle,
            bars: makeBars(from: projection.points, axisTicks: input.horizon.axisTicks),
            inputs: [makeInput(.initialBalance, input: input), makeInput(.monthlyTopUp, input: input)]
        )
    }
}

// MARK: - Private

private extension EarnCalculatorViewStateBuilder {
    func sample(_ points: [EarnCalculatorProjection.Point], count: Int) -> [EarnCalculatorProjection.Point] {
        guard points.count > count else {
            return points
        }

        return (1 ... count).map { index in
            points[index * points.count / count - 1]
        }
    }

    func makeIncentiveBadgeText(apy: Decimal) -> String {
        Localization.yieldModulePromoScreenIncentivisedChip(percentFormatter.format(apy, option: .yieldPromo))
    }

    func makeBars(
        from points: [EarnCalculatorProjection.Point],
        axisTicks: [EarnCalculatorHorizon.AxisTick]
    ) -> [EarnCalculatorViewState.Bar] {
        let sampled = sample(points, count: Constants.maxBarCount)
        let maxBalance = sampled.map(\.balance).max() ?? .zero
        let axisLabels = assignAxisLabels(axisTicks, to: sampled)

        return sampled.enumerated().map { index, point in
            EarnCalculatorViewState.Bar(
                id: index,
                month: point.month,
                axisLabel: axisLabels[index],
                normalizedHeight: maxBalance > .zero ? NSDecimalNumber(decimal: point.balance / maxBalance).doubleValue : .zero,
                balance: balanceFormatter.formatFiatBalance(point.balance, currencyCode: currencyCode),
                earned: formatEarned(point.earned)
            )
        }
    }

    func assignAxisLabels(
        _ ticks: [EarnCalculatorHorizon.AxisTick],
        to points: [EarnCalculatorProjection.Point]
    ) -> [Int: String] {
        ticks.reduce(into: [:]) { labels, tick in
            let nearestIndex = points.indices.min { lhs, rhs in
                abs(points[lhs].month - tick.month) < abs(points[rhs].month - tick.month)
            }

            if let nearestIndex {
                labels[nearestIndex] = tick.label
            }
        }
    }

    func makeInput(_ field: EarnCalculatorField, input: EarnCalculatorInput) -> EarnCalculatorViewState.Input {
        let value = input[field]

        return EarnCalculatorViewState.Input(
            field: field,
            title: field.title,
            currencySymbol: currencySymbol,
            value: balanceFormatter.formatFiatBalance(
                value,
                currencyCode: currencyCode,
                formattingOptions: Constants.wholeNumberOptions
            ),
            canDecrease: value > field.range.lowerBound,
            canIncrease: value < field.range.upperBound
        )
    }

    func formatEarned(_ value: Decimal) -> String {
        let rounded = value.rounded(scale: 0, roundingMode: .plain)
        let formatted = balanceFormatter.formatFiatBalance(
            rounded,
            currencyCode: currencyCode,
            formattingOptions: Constants.wholeNumberOptions
        )

        return rounded > .zero ? String.plusSign + formatted : formatted
    }

    var currencySymbol: String {
        BalanceNumberFormatterCache
            .fiatFormatter(forCurrencyCode: currencyCode, locale: .current, formattingOptions: .defaultFiatFormattingOptions)
            .currencySymbol
    }
}

// MARK: - Constants

private extension EarnCalculatorViewStateBuilder {
    enum Constants {
        static let maxBarCount = 24
        static let wholeNumberOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: 0)
        )
    }
}
