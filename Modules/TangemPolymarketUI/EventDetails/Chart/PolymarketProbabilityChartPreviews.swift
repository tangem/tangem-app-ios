//
//  PolymarketProbabilityChartPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation

private struct PolymarketProbabilityChartShowcase: View {
    @State private var period = PolymarketPriceIntervalStub.day.id

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketProbabilityChart(model: .liveStub(period: period, onSelect: { period = $0 }))

                PolymarketProbabilityChart(model: .futuresStub)

                PolymarketProbabilityChart(model: .threeWayStub)

                PolymarketProbabilityChart(model: .loadingStub)

                PolymarketProbabilityChart(model: .flatStub)

                PolymarketProbabilityChart(model: .noDataStub)

                PolymarketProbabilityChart.skeleton()
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketProbabilityChartShowcase {
    enum Constants {
        static let spacing: CGFloat = 32
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketProbabilityChart.Model {
    static func liveStub(period: String, onSelect: @escaping (String) -> Void) -> Self {
        Self(
            series: [
                .curve(color: .affirmative, title: "Conventus Stellarum", percents: favourite, hours: 3),
                .curve(color: .negative, title: "1win", percents: favourite.map { 100 - $0 }, hours: 3),
            ],
            dateLabels: ["11:00 AM", "12:00 AM", "13:00 AM"],
            periods: .init(items: PolymarketPriceIntervalStub.periods, selectedID: period),
            probabilityText: percentText,
            onSelectPeriod: onSelect
        )
    }

    static let loadingStub = PolymarketProbabilityChart.Model(
        series: [
            .curve(color: .affirmative, title: "Conventus Stellarum", percents: favourite, hours: 3),
            .curve(color: .negative, title: "1win", percents: favourite.map { 100 - $0 }, hours: 3),
        ],
        dateLabels: ["11:00 AM", "12:00 AM", "13:00 AM"],
        periods: .init(items: PolymarketPriceIntervalStub.periods, selectedID: PolymarketPriceIntervalStub.day.id),
        isLoading: true,
        probabilityText: percentText
    )

    static let flatStub = PolymarketProbabilityChart.Model(
        series: [
            .curve(color: .affirmative, title: "Yes", percents: Array(repeating: 50, count: 24), hours: 6),
            .curve(color: .negative, title: "No", percents: Array(repeating: 50, count: 24), hours: 6),
        ],
        dateLabels: ["6:00 AM", "9:00 AM", "12:00 PM"],
        latestMarker: .hidden,
        probabilityText: percentText
    )

    static let noDataStub = PolymarketProbabilityChart.Model(
        series: [
            .curve(color: .affirmative, title: "Yes", percents: [], hours: 1),
            .curve(color: .negative, title: "No", percents: [], hours: 1),
        ],
        dateLabels: [],
        periods: .init(items: PolymarketPriceIntervalStub.periods, selectedID: PolymarketPriceIntervalStub.hour.id),
        probabilityText: percentText
    )

    private static let favourite: [Double] = [
        44, 44, 45, 44, 43, 45, 50, 57, 60, 55, 50, 53, 60, 64, 65, 63, 58, 55,
    ]

    static let futuresStub = PolymarketProbabilityChart.Model(
        series: [
            .stub(color: .blue, title: "Buffalo Bills", percent: 28, start: 52, seed: 3, hours: 120 * 24),
            .stub(color: .green, title: "Los Angeles Rams", percent: 25, start: 41, seed: 17, hours: 120 * 24),
            .stub(color: .red, title: "San Francisco 49ers", percent: 25, start: 34, seed: 29, hours: 120 * 24),
            .stub(color: .yellow, title: "Kansas City Chiefs", percent: 22, start: 24, seed: 57, hours: 120 * 24),
        ],
        dateLabels: ["Jun", "Jul", "Aug", "Sep"],
        periods: .init(items: PolymarketPriceIntervalStub.periods, selectedID: PolymarketPriceIntervalStub.allTime.id),
        probabilityText: percentText
    )

    static let threeWayStub = PolymarketProbabilityChart.Model(
        series: [
            .stub(color: .red, title: "Otelul Galati", percent: 36, start: 42, seed: 7, hours: 10 * 24),
            .stub(color: .blue, title: "FC Corvinul 1921 Hunedoara", percent: 34, start: 28, seed: 21, hours: 10 * 24),
            .stub(color: .draw, title: "Draw", percent: 32, start: 30, seed: 43, hours: 10 * 24),
        ],
        dateLabels: ["Sep 10", "Sep 13", "Sep 16", "Sep 19"],
        probabilityText: percentText
    )

    private static let percentText: (Decimal) -> String = { probability in
        let percent = probability.doubleValue * 100

        return "\(Int(percent.rounded()))%"
    }
}

private extension PolymarketProbabilityChart.Series {
    static func curve(color: PolymarketProbabilityChart.SeriesColor, title: String, percents: [Double], hours: Int) -> Self {
        let origin = Date(timeIntervalSince1970: 1_757_462_400)
        let interval = Double(hours * 60 * 60) / Double(max(percents.count - 1, 1))

        return Self(
            id: title,
            title: title,
            probabilityText: "\(Int(percents.last ?? 0))%",
            color: color,
            points: percents.enumerated().map { step, percent in
                PolymarketProbabilityChart.Point(
                    date: origin.addingTimeInterval(interval * Double(step)),
                    probability: Decimal(percent / 100)
                )
            }
        )
    }

    static func stub(color: PolymarketProbabilityChart.SeriesColor, title: String, percent: Int, start: Double, seed: UInt64, hours: Int) -> Self {
        Self(
            id: title,
            title: title,
            probabilityText: "\(percent)%",
            color: color,
            points: walk(from: start, to: Double(percent), seed: seed, hours: hours)
        )
    }

    private static func walk(from start: Double, to end: Double, seed: UInt64, hours: Int) -> [PolymarketProbabilityChart.Point] {
        let steps = 240
        let origin = Date(timeIntervalSince1970: 1_757_462_400)
        let interval = Double(hours * 60 * 60) / Double(steps)
        var noise = seed

        return (0 ... steps).map { step in
            noise = noise &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let jitter = Double((noise >> 33) % 1000) / 1000 - 0.5
            let progress = Double(step) / Double(steps)
            let drift = start + (end - start) * progress + jitter * 6
            let percent = clamp(drift, min: 1, max: 99)

            return PolymarketProbabilityChart.Point(
                date: origin.addingTimeInterval(interval * Double(step)),
                probability: Decimal(percent / 100)
            )
        }
    }
}

// MARK: - Periods

private enum PolymarketPriceIntervalStub {
    static let hour = PolymarketProbabilityChart.Period(id: "1h", title: "1H")
    static let sixHours = PolymarketProbabilityChart.Period(id: "6h", title: "6H")
    static let day = PolymarketProbabilityChart.Period(id: "1d", title: "1D")
    static let allTime = PolymarketProbabilityChart.Period(id: "max", title: "MAX")

    static let periods = [hour, sixHours, day, allTime]
}

// MARK: - Previews

#Preview {
    PolymarketProbabilityChartShowcase()
        .preferredColorScheme(.dark)
}
