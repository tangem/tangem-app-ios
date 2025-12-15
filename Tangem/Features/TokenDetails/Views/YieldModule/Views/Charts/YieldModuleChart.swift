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

struct YieldModuleChart: View {
    let state: State

    var body: some View {
        let bars = makeBars()
        let xMap = makeXLabelMap(barsCount: bars.count)
        let average = averageApy()

        return Chart {
            ForEach(bars) { bar in
                BarMark(x: .value("Index", bar.idx), y: .value("APR", bar.apr))
                    .cornerRadius(2)
                    .foregroundStyle(Colors.Icon.accent)
            }

            if let average {
                RuleMark(y: .value("Average", average))
                    .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Colors.Icon.primary1)
                    .annotation(position: .overlay, alignment: .leading) {
                        Text(Localization.yieldModuleRateInfoSheetChartAverage(PercentFormatter().format(average, option: .staking)))
                            .style(Fonts.Bold.caption2, color: Colors.Text.primary2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Rectangle().fill(Colors.Icon.primary1).cornerRadius(8, corners: .allCorners))
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
                            .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                            .skeletonable(isShown: state.isLoading)
                    }

                    AxisGridLine().foregroundStyle(.clear)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 0.03, 0.06, 0.09]) { mark in
                AxisGridLine()
                AxisValueLabel {
                    if let v = mark.as(Double.self) {
                        Text(v, format: .percent.precision(.fractionLength(0)))
                            .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                            .skeletonable(isShown: state.isLoading)
                    }
                }
            }
        }
        .chartYScale(domain: 0.0 ... Constants.maxYValue)
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

    private func makeBars() -> [Bar] {
        switch state {
        case .loading:
            return (0 ... 31).map { Bar(idx: $0, apr: 0) }
        case .loaded(let data, _, _):
            return data.enumerated().map { index, bar in
                Bar(idx: index, apr: min(bar / 100, Constants.maxYValue))
            }
        }
    }

    private func makeXLabelMap(barsCount: Int) -> [Int: String] {
        guard barsCount > 1 else { return [:] }
        let labels: [String]

        switch state {
        case .loaded(_, let xLabels, _) where !xLabels.isEmpty:
            labels = xLabels
        case .loading, .loaded:
            labels = Array(repeating: "Aaa", count: 5)
        }

        let ticks = [0, 7, 14, 21, 27]
        return Dictionary(uniqueKeysWithValues: zip(ticks, labels))
    }

    private func makeXLabels() -> [String] {
        switch state {
        case .loading:
            return Array(repeating: "Aaa", count: 5)
        case .loaded(_, let xAxisLabels, _):
            return xAxisLabels
        }
    }
}

// MARK: - State

extension YieldModuleChart {
    enum State {
        case loading
        case loaded(apyData: [Double], xAxisLabels: [String], averageApy: Double?)

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

extension YieldModuleChart {
    enum Constants {
        static let maxYValue: Double = 0.12
    }
}
