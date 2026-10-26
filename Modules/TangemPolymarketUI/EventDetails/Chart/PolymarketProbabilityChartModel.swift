//
//  PolymarketProbabilityChartModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemUI

public extension PolymarketProbabilityChart {
    struct Model {
        public let series: [Series]
        public let dateLabels: [String]
        public let periods: Periods?
        public let isLoading: Bool
        public let latestMarker: LatestMarker
        public let legendLineCount: Int
        public let animatesChanges: Bool
        public let probabilityText: (Decimal) -> String
        public let onSelectPeriod: (String) -> Void

        public init(
            series: [Series],
            dateLabels: [String],
            periods: Periods? = nil,
            isLoading: Bool = false,
            latestMarker: LatestMarker = .still,
            legendLineCount: Int = 2,
            animatesChanges: Bool = false,
            probabilityText: @escaping (Decimal) -> String,
            onSelectPeriod: @escaping (String) -> Void = { _ in }
        ) {
            self.series = series
            self.dateLabels = dateLabels
            self.periods = periods
            self.isLoading = isLoading
            self.latestMarker = latestMarker
            self.legendLineCount = legendLineCount
            self.animatesChanges = animatesChanges
            self.probabilityText = probabilityText
            self.onSelectPeriod = onSelectPeriod
        }
    }

    struct Periods {
        public let items: [Period]
        public let selectedID: String

        public init?(items: [Period], selectedID: String) {
            guard items.contains(where: { $0.id == selectedID }) else {
                return nil
            }

            self.items = items
            self.selectedID = selectedID
        }
    }

    enum LatestMarker {
        case hidden
        case still
        case pulsing
    }

    struct Period: Identifiable, Hashable {
        public let id: String
        public let title: String

        public init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    enum SeriesColor: Hashable {
        case affirmative
        case negative
        case blue
        case green
        case red
        case yellow
        case draw
    }

    struct Series: Identifiable, Equatable {
        public let id: String
        public let title: String
        public let probabilityText: String
        public let color: SeriesColor
        public let points: [Point]

        public init(
            id: String,
            title: String,
            probabilityText: String,
            color: SeriesColor,
            points: [Point]
        ) {
            self.id = id
            self.title = title
            self.probabilityText = probabilityText
            self.color = color
            self.points = points.normalized()
        }
    }

    struct Point: Equatable {
        public let date: Date
        public let probability: Decimal

        public init(date: Date, probability: Decimal) {
            self.date = date
            self.probability = probability
        }
    }
}

// MARK: - Palette

public extension PolymarketProbabilityChart {
    static func color(forSeriesAt index: Int) -> SeriesColor {
        Constants.palette[index % Constants.palette.count]
    }
}

// MARK: - Series colors

extension PolymarketProbabilityChart.SeriesColor {
    var line: Color {
        switch self {
        case .affirmative: DesignSystem.Color.borderStatusInfo
        case .negative: DesignSystem.Color.borderStatusError
        case .blue: DesignSystem.Color.borderAccentBlue
        case .green: DesignSystem.Color.borderAccentGreen
        case .red: DesignSystem.Color.borderAccentRed
        case .yellow: DesignSystem.Color.borderAccentYellow
        case .draw: DesignSystem.Color.borderAccentNeutral
        }
    }

    var marker: Color {
        switch self {
        case .affirmative, .blue: DesignSystem.Color.iconAccentBlue
        case .negative, .red: DesignSystem.Color.iconAccentRed
        case .green: DesignSystem.Color.iconAccentGreen
        case .yellow: DesignSystem.Color.iconAccentYellow
        case .draw: DesignSystem.Color.iconAccentNeutral
        }
    }
}

// MARK: - Normalization

private extension [PolymarketProbabilityChart.Point] {
    func normalized() -> Self {
        Dictionary(map { ($0.date, $0) }, uniquingKeysWith: { _, latest in latest })
            .values
            .sorted { $0.date < $1.date }
    }
}
