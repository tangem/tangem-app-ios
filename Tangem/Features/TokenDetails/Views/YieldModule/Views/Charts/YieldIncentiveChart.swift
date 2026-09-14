//
//  YieldIncentiveChart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Charts
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization

/// Plots base supply APY with the Merkl reward cap stacked on top. Kept apart from `YieldModuleChart` because the
/// incentivised series carries its own scale, labels and styling.
struct YieldIncentiveChart: View {
    /// `nil` renders the loading skeleton.
    let data: YieldIncentiveChartData?

    var body: some View {
        let bars = makeBars()

        return Chart {
            ForEach(bars) { bar in
                BarMark(x: .value("Index", bar.index), y: .value("Base APY", bar.baseApy))
                    .cornerRadius(2)
                    .foregroundStyle(DesignSystem.Color.bgBrand)

                if bar.rewardsApr > 0 {
                    BarMark(
                        x: .value("Index", bar.index),
                        yStart: .value("Base APY", bar.baseApy + Constants.rewardsCapGap),
                        yEnd: .value("Total APY", bar.baseApy + Constants.rewardsCapGap + bar.rewardsApr)
                    )
                    .cornerRadius(2)
                    .foregroundStyle(DesignSystem.Color.bgStatusInfoSubtle)
                }
            }

            if let averageApy {
                RuleMark(y: .value("Average APY", averageApy))
                    .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Colors.Icon.primary1)
                    .annotation(position: .overlay, alignment: .leading) {
                        Text(Localization.yieldModuleRateInfoSheetChartAverage(PercentFormatter().format(averageApy, option: .earn)))
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
            AxisMarks(values: xTicks.keys.sorted()) { tick in
                if let index = tick.as(Int.self), let label = xTicks[index] {
                    AxisValueLabel {
                        Text(label)
                            .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                            .skeletonable(isShown: data == nil)
                    }

                    AxisGridLine().foregroundStyle(.clear)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { mark in
                AxisGridLine()
                AxisValueLabel {
                    if let value = mark.as(Double.self) {
                        Text(value, format: .percent.precision(.fractionLength(0)))
                            .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                            .skeletonable(isShown: data == nil)
                    }
                }
            }
        }
        .chartYScale(domain: 0.0 ... yDomainMax)
        .chartPlotStyle { plot in
            plot.frame(height: Constants.plotHeight)
        }
    }

    // MARK: - Private Implementation

    private var averageApy: Decimal? {
        data?.averageApy.map { Decimal(floatLiteral: $0) / 100 }
    }

    private var xTicks: [Int: String] {
        guard let data else {
            return Dictionary(uniqueKeysWithValues: zip(Constants.skeletonTicks, Constants.skeletonLabels))
        }

        return data.xTicks
    }

    /// Total APY with rewards outgrows the base-yield scale, so the ceiling follows the plotted peak and only falls
    /// back to the base-yield one while the series stays below it.
    private var yDomainMax: Double {
        let peakPercent = max(dataPeak, Constants.minYDomainMax) * 100
        let stepPercent = (peakPercent / Double(Constants.yTickCount)).rounded(.up)

        return stepPercent * Double(Constants.yTickCount) / 100
    }

    private var yAxisValues: [Double] {
        let step = yDomainMax / Double(Constants.yTickCount)

        return (0 ..< Constants.yTickCount).map { Double($0) * step }
    }

    private var dataPeak: Double {
        let barsPeak = makeBars().reduce(0.0) { peak, bar in
            let total = bar.rewardsApr > 0
                ? bar.baseApy + Constants.rewardsCapGap + bar.rewardsApr
                : bar.baseApy

            return max(peak, total)
        }

        return max(barsPeak, averageApy.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0)
    }

    private func makeBars() -> [Bar] {
        guard let data else {
            return (0 ..< Constants.skeletonBarsCount).map { Bar(index: $0, baseApy: 0, rewardsApr: 0) }
        }

        return data.baseApyData.enumerated().map { index, baseApy in
            Bar(
                index: index,
                baseApy: baseApy / 100,
                rewardsApr: (data.rewardsAprData[safe: index] ?? 0) / 100
            )
        }
    }
}

// MARK: - Bar

private extension YieldIncentiveChart {
    struct Bar: Identifiable {
        var id: Int { index }

        let index: Int
        let baseApy: Double
        let rewardsApr: Double
    }
}

// MARK: - Constants

private extension YieldIncentiveChart {
    enum Constants {
        /// The design sizes the plot area itself, with the axis labels laid out around it.
        static let plotHeight: CGFloat = 128
        static let minYDomainMax: Double = 0.12
        static let yTickCount = 4
        /// Keeps the reward cap visually detached from the base segment.
        static let rewardsCapGap: Double = 0.0015
        static let skeletonBarsCount = 32
        static let skeletonTicks = [0, 7, 14, 21, 27]
        static let skeletonLabels = Array(repeating: "Aaa", count: 5)
    }
}

// MARK: - Previews

#Preview("Base yield scale") {
    YieldIncentiveChart(
        data: YieldIncentiveChartData(
            baseApyData: (0 ..< 28).map { 3.5 + Double($0 % 5) * 0.4 },
            rewardsAprData: [],
            xTicks: [0: "Jan", 14: "Feb"],
            averageApy: 4.3
        )
    )
    .padding()
}

#Preview("Merkl total") {
    YieldIncentiveChart(
        data: YieldIncentiveChartData(
            baseApyData: (0 ..< 28).map { 4.0 + Double($0 % 4) * 0.3 },
            rewardsAprData: (0 ..< 28).map { 11.0 + Double($0 % 6) * 0.8 },
            xTicks: [0: "Jan", 14: "Feb"],
            averageApy: 17.4
        )
    )
    .padding()
}
