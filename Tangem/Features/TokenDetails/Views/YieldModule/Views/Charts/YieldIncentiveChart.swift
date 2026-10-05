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
import TangemUI
import TangemUIUtils

/// Plots base supply APY with the Merkl reward cap stacked on top. Kept apart from `YieldModuleChart` because the
/// incentivised series carries its own scale, labels and styling.
struct YieldIncentiveChart: View {
    /// `nil` renders the loading skeleton.
    let data: YieldIncentiveChartData?

    var body: some View {
        let bars = makeBars()
        let capGap = capGap

        return Chart {
            ForEach(bars) { bar in
                BarMark(
                    x: .value("Index", bar.index),
                    y: .value("Base APY", bar.baseApy),
                    width: .fixed(Constants.barWidth)
                )
                .cornerRadius(Constants.barCornerRadius)
                .foregroundStyle(DesignSystem.Color.bgBrand)

                if bar.rewardsApr > 0 {
                    BarMark(
                        x: .value("Index", bar.index),
                        yStart: .value("Base APY", bar.baseApy + capGap),
                        yEnd: .value("Total APY", bar.baseApy + capGap + bar.rewardsApr),
                        width: .fixed(Constants.barWidth)
                    )
                    .cornerRadius(Constants.barCornerRadius)
                    .foregroundStyle(DesignSystem.Color.bgStatusInfoSubtle)
                }
            }
        }
        .chartXScale(domain: Constants.xDomainInset ... (Double(bars.count) + Constants.xDomainInset))
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                averageOverlay(proxy: proxy, geometry: geometry, barsCount: bars.count)
            }
        }
    }

    // MARK: - Private Implementation

    @ViewBuilder
    private func averageOverlay(proxy: ChartProxy, geometry: GeometryProxy, barsCount: Int) -> some View {
        if barsCount > 0,
           let averageApy,
           let plotStart = proxy.position(forX: Constants.xDomainInset),
           let plotEnd = proxy.position(forX: Double(barsCount) + Constants.xDomainInset),
           let averagePosition = proxy.position(forY: NSDecimalNumber(decimal: averageApy).doubleValue) {
            let plotWidth = plotEnd - plotStart

            HStack(spacing: Constants.averageLineSpacing) {
                averageBadge(averageApy)

                HorizontalLine()
                    .stroke(
                        DesignSystem.Color.iconPrimary,
                        style: StrokeStyle(lineWidth: Constants.averageLineWidth, dash: Constants.averageLineDash)
                    )
                    .frame(height: Constants.averageLineWidth)
            }
            .frame(width: plotWidth)
            .position(x: geometry.size.width - plotWidth / 2, y: averagePosition)
        }
    }

    private func averageBadge(_ averageApy: Decimal) -> some View {
        Text(Localization.yieldModuleRateInfoSheetChartAverage(PercentFormatter().format(averageApy, option: .earn)))
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
            .padding(.horizontal, Constants.averageBadgeHorizontalPadding)
            .padding(.vertical, Constants.averageBadgeVerticalPadding)
            .tangemMaterialSurface(in: Capsule())
    }

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
        roundedDomain(for: dataPeak + capGap)
    }

    /// The design detaches the cap from the base by a constant 2pt, so the gap is carried in the data units
    /// that map onto it at the current scale.
    private var capGap: Double {
        Double(Constants.capGap / Constants.plotHeight) * roundedDomain(for: dataPeak)
    }

    private func roundedDomain(for peak: Double) -> Double {
        let peakPercent = max(peak, Constants.minYDomainMax) * 100
        let stepPercent = (peakPercent / Double(Constants.yTickCount)).rounded(.up)

        return stepPercent * Double(Constants.yTickCount) / 100
    }

    private var yAxisValues: [Double] {
        let step = yDomainMax / Double(Constants.yTickCount)

        return (0 ..< Constants.yTickCount).map { Double($0) * step }
    }

    private var dataPeak: Double {
        let barsPeak = makeBars().reduce(0.0) { peak, bar in
            max(peak, bar.baseApy + bar.rewardsApr)
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

// MARK: - Horizontal line

private struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
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
        static let barWidth: CGFloat = 4
        static let barCornerRadius: CGFloat = 2
        static let capGap: CGFloat = 2
        static let xDomainInset: Double = -0.5
        static let averageBadgeHorizontalPadding: CGFloat = 10
        static let averageBadgeVerticalPadding: CGFloat = 8
        static let averageLineSpacing: CGFloat = 4
        static let averageLineWidth: CGFloat = 1
        static let averageLineDash: [CGFloat] = [4, 2]
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
