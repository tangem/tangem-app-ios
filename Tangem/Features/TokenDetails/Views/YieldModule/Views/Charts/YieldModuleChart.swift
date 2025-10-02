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
    let state: YieldChartState

    // MARK: - View Body

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                yAxis(height: Constants.chartSectionHeight)
                chartArea
            }

            xLabels(state: state)
        }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private func xLabels(state: YieldChartState) -> some View {
        var labels: [String] {
            if case .loaded(let yieldChartData) = state {
                return yieldChartData.xLabels
            }

            return Array(repeating: "AAA", count: 5)
        }

        HStack(spacing: 40) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .skeletonable(isShown: state.isLoading)
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

    @ViewBuilder
    private var chartArea: some View {
        switch state {
        case .loading:
            loader
        case .error:
            EmptyView()
        case .loaded(let data):
            bars(buckets: data.buckets, averageApy: data.averageApy)
        }
    }

    private var loader: some View {
        ProgressView()
            .frame(width: 280, height: 90)
            .background {
                gridLines(height: Constants.chartSectionHeight)
                    .padding(.horizontal, -6)
            }
    }

    private func errorView(action: @escaping () async -> Void) -> some View {
        VStack(spacing: 12) {
            Text(Localization.unexpectedErrorTitle)
                .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)

            Button(action: { Task { await action() } }) {
                Text(Localization.alertButtonTryAgain)
                    .style(Fonts.Regular.caption2, color: Colors.Text.primary1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
            }
        }
    }

    private func bars(buckets: [Double], averageApy: Double) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(buckets.indices, id: \.self) { index in
                let value = buckets[index]
                let ratio = min(value, Constants.yMax) / Constants.yMax
                let targetHeight = Constants.chartSectionHeight * CGFloat(ratio)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Colors.Icon.accent)
                    .frame(width: 6, height: targetHeight)
            }
        }
        .frame(height: Constants.chartSectionHeight, alignment: .bottom)
        .frame(alignment: .leading)
        .overlay {
            avgOverlay(averageApy: averageApy)
        }
        .background {
            gridLines(height: Constants.chartSectionHeight)
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
                            .skeletonable(isShown: state.isLoading, width: 18, height: 16, radius: 4)
                            .style(Fonts.Bold.caption2, color: Colors.Text.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: 2),
                        alignment: .bottom
                    )
            }
        }
    }

    private func avgOverlay(averageApy: Double) -> some View {
        GeometryReader { geo in
            let avgRatio = averageApy / Constants.yMax
            let y = geo.size.height - geo.size.height * CGFloat(avgRatio)
            let averageString = String(format: "%.2f", averageApy) + "%"

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
