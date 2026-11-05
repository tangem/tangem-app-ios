//
//  YieldModuleChart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Charts
import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldModuleChart: View {
    let state: State
    var yScale: YScale = .fixed

    var body: some View {
        let yAxis = makeYAxis()
        let bars = makeBars(yMax: yAxis.max)
        let xMap = makeXLabelMap(barsCount: bars.count)
        let average = averageApy()

        return Chart {
            ForEach(bars) { bar in
                BarMark(x: .value("Index", bar.idx), y: .value("APR", bar.apr))
                    .cornerRadius(2)
                    .foregroundStyle(DesignSystem.Color.bgAccentBlue)
            }

            if let average {
                RuleMark(y: .value("Average", average))
                    .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(DesignSystem.Color.borderAccentNeutral)
                    .annotation(position: .overlay, alignment: .leading) {
                        Text(Localization.yieldModuleRateInfoSheetChartAverage(PercentFormatter().format(average, option: .earn)))
                            .style(Fonts.Bold.caption2, color: DesignSystem.Color.textInversePrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Rectangle().fill(DesignSystem.Color.bgInverse).cornerRadius(8, corners: .allCorners))
                            .offset(y: -16)
                    }
            }
        }
        .chartXScale(domain: -0.5 ... (Double(bars.count) - 0.5))
        .chartXAxis {
            AxisMarks(values: xMap.keys.sorted()) { tick in
                if let i = tick.as(Int.self), let text = xMap[i] {
                    AxisValueLabel {
                        Text(text)
                            .style(Fonts.Regular.caption2, color: DesignSystem.Color.textSecondary)
                            .shimmerPlaceholder(state.isLoading)
                    }

                    AxisGridLine().foregroundStyle(.clear)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxis.ticks) { mark in
                AxisGridLine()
                AxisValueLabel {
                    if let v = mark.as(Double.self) {
                        Text(v, format: .percent.precision(.fractionLength(0 ... 2)))
                            .style(Fonts.Regular.caption2, color: DesignSystem.Color.textSecondary)
                            .shimmerPlaceholder(state.isLoading)
                    }
                }
            }
        }
        .chartYScale(domain: 0.0 ... yAxis.max)
        .frame(height: 110)
    }

    // MARK: - Private Implementation

    private func averageApy() -> Decimal? {
        switch state {
        case .loading:
            return nil
        case .loaded(_, _, let avg):
            return avg.map {
                Decimal(floatLiteral: $0) / 100
            }
        }
    }

    private func makeYAxis() -> (ticks: [Double], max: Double) {
        let fixed = (ticks: Constants.fixedYTicks, max: Constants.maxYValue)

        guard yScale == .fitted, case .loaded(let data, _, let average) = state else {
            return fixed
        }

        let peak = max(data.max() ?? 0, average ?? 0) / 100
        let ticks = YScale.fittedTicks(peak: peak)

        return ticks.last.map { (ticks: ticks, max: $0) } ?? fixed
    }

    private func makeBars(yMax: Double) -> [Bar] {
        switch state {
        case .loading:
            return (0 ... 31).map { Bar(idx: $0, apr: 0) }
        case .loaded(let data, _, _):
            return data.enumerated().map { index, bar in
                Bar(idx: index, apr: min(bar / 100, yMax))
            }
        }
    }

    private func makeXLabelMap(barsCount: Int) -> [Int: String] {
        guard barsCount > 1 else { return [:] }

        switch state {
        case .loaded(_, let xTicks, _):
            return xTicks
        case .loading:
            let ticks = [0, 7, 14, 21, 27].filter { $0 < barsCount }
            return Dictionary(uniqueKeysWithValues: ticks.map { ($0, "Aaa") })
        }
    }
}

// MARK: - State

extension YieldModuleChart {
    enum State {
        case loading
        case loaded(apyData: [Double], xAxisTicks: [Int: String], averageApy: Double?)

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .loaded:
                return false
            }
        }
    }
}

// MARK: - Bar

extension YieldModuleChart {
    struct Bar: Identifiable {
        let id = UUID()
        let idx: Int
        let apr: Double
    }
}

// MARK: - YScale

extension YieldModuleChart {
    enum YScale {
        case fixed
        case fitted

        static func fittedTicks(peak: Double) -> [Double] {
            let top = peak * Constants.fittedHeadroom

            guard top > 0, let step = Constants.fittedSteps.first(where: { $0 * Double(Constants.fittedTickCount - 1) >= top }) else {
                return []
            }

            return (0 ..< Constants.fittedTickCount).map { Double($0) * step }
        }
    }
}

extension YieldModuleChart {
    enum Constants {
        static let maxYValue: Double = 0.12
        static let fixedYTicks: [Double] = [0.0, 0.03, 0.06, 0.09]
        static let fittedTickCount = 4
        static let fittedHeadroom = 1.25
        static let fittedSteps: [Double] = [0.0025, 0.005, 0.01, 0.02, 0.025, 0.03, 0.04, 0.05, 0.1, 0.25, 0.5, 1]
    }
}
