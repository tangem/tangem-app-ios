//
//  YieldModuleChart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldMduleChartContainer: View {
    let data: YieldChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            title
            description
            YieldModuleChart(data: data)
                .border(Color.red)
        }
        .defaultRoundedBackground()
    }

    private var title: some View {
        Text(Localization.yieldModuleRateInfoSheetChartTitle)
            .style(Fonts.Bold.headline, color: Colors.Text.primary1)
    }

    private var description: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Colors.Icon.accent)
                .frame(width: 8, height: 8)

            Text("Supply APR")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
    }
}

struct YieldModuleChart: View {
    let data: YieldChartData

    // MARK: - View Body

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                yAxis
                bars
            }
            .frame(height: Constants.chartSectionHeight)

            xLabels(data.xLabels)
                .padding(.leading, 24)
        }
    }

    // MARK: - Sub Views

    private func xLabels(_ labels: [String]) -> some View {
        HStack(spacing: 40) {
            ForEach(labels, id: \.self) { label in
                Text(label)
            }
        }
        .style(Fonts.Bold.caption2, color: Colors.Text.tertiary)
        .frame(maxWidth: .infinity)
    }

    var gridLines: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let sectionH = h / 4
            let line = 1 / UIScreen.main.scale

            VStack(spacing: 0) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    Color.clear
                        .frame(height: sectionH)
                        .overlay(
                            Rectangle()
                                .fill(Colors.Icon.inactive.opacity(0.1))
                                .frame(height: line),
                            alignment: .bottom
                        )
                }
            }
        }
    }

    private var bars: some View {
        let yMax = Constants.yMax

        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(data.buckets.indices, id: \.self) { index in
                let value = data.buckets[index]
                let ratio = min(value, yMax) / yMax
                let targetHeight = Constants.chartSectionHeight * CGFloat(ratio)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Colors.Icon.accent)
                    .frame(width: 6, height: targetHeight)
            }
        }
        .frame(height: Constants.chartSectionHeight, alignment: .bottom)
        .frame(alignment: .leading)
        .overlay {
            avgOverlay
        }
        .background {
            gridLines
                .padding(.horizontal, -6)
        }
    }

    private var yAxis: some View {
        GeometryReader { geo in
            let sectionH = geo.size.height / 4

            VStack(spacing: 0) {
                ForEach([9, 6, 3, 0], id: \.self) { i in
                    Color.clear
                        .frame(height: sectionH)
                        .overlay(
                            Text("\(i)%")
                                .style(Fonts.Bold.caption2, color: Colors.Text.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(y: 2),
                            alignment: .bottom
                        )
                }
            }
        }
        .frame(width: 28)
    }

    private var avgOverlay: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let yMax: Double = 12
            let avgRatio = data.averageApy / yMax
            let y = height - height * CGFloat(avgRatio)

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(Colors.Icon.primary1, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))

                Text("Avg \(String(format: "%.2f", data.averageApy))%")
                    .style(Fonts.Bold.caption2, color: Colors.Text.disabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Colors.Icon.primary1)
                    )
                    .offset(x: 0, y: y - 28)
            }
        }
    }
}

private extension YieldModuleChart {
    enum Constants {
        static let chartSectionHeight: CGFloat = 90
        static let yMax: CGFloat = 12
    }
}
