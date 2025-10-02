//
//  YieldModuleChart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct YieldModuleChart: View {
    let data: YieldChartData

    // MARK: - View Body

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                yAxis(height: Constants.chartSectionHeight)
                bars(height: Constants.chartSectionHeight)
            }

            xLabels(data.xLabels)
        }
    }

    // MARK: - Sub Views

    private func xLabels(_ labels: [String]) -> some View {
        HStack(spacing: 40) {
            ForEach(labels, id: \.self) { label in
                Text(label)
            }
        }
        .padding(.leading, 28)
        .style(Fonts.Bold.caption2, color: Colors.Text.tertiary)
        .frame(maxWidth: .infinity)
    }

    private func gridLines(height: CGFloat) -> some View {
        let sectionH = height / 4
        let line = 1 / UIScreen.main.scale

        return VStack(spacing: 0) {
            ForEach(0 ..< 4, id: \.self) { _ in
                Color.clear
                    .frame(height: sectionH)
                    .overlay(
                        Rectangle()
                            .fill(Colors.Icon.inactive.opacity(0.9))
                            .frame(height: line),
                        alignment: .bottom
                    )
            }
        }
    }

    private func bars(height: CGFloat) -> some View {
        let yMax = Constants.yMax

        return HStack(alignment: .bottom, spacing: 4) {
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
            gridLines(height: height)
                .padding(.horizontal, -6)
        }
    }

    private func yAxis(height: CGFloat) -> some View {
        let sectionH = height / 4

        return VStack(spacing: 0) {
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

    private var avgOverlay: some View {
        GeometryReader { geo in
            let avgRatio = data.averageApy / Constants.yMax
            let y = geo.size.height - geo.size.height * CGFloat(avgRatio)
            let averageString = String(format: "%.2f", data.averageApy) + "%"

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(Colors.Icon.primary1, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                .padding(.trailing, 14)

                Text(Localization.yieldModuleRateInfoSheetChartAverage(averageString))
                    .style(Fonts.Bold.caption2, color: Colors.Text.disabled)
                    .padding(6)
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
