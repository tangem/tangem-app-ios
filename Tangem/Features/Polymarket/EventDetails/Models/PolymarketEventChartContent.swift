//
//  PolymarketEventChartContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

struct PolymarketEventChartContent {
    let outcomes: [Outcome]
    let intervals: [PolymarketPriceInterval]
    let initialInterval: PolymarketPriceInterval
    let lifetime: PolymarketMarketLifetime
    let isLive: Bool
    let isComplementaryPair: Bool

    var periods: [PolymarketProbabilityChart.Period] {
        intervals.map { PolymarketProbabilityChart.Period(id: $0.rawValue, title: $0.title(isLive: isLive)) }
    }

    func streamsLivePoints(on interval: PolymarketPriceInterval) -> Bool {
        isLive && interval == .hour
    }

    func historyQuery(for interval: PolymarketPriceInterval, now: Date = Date()) -> PolymarketPriceHistoryQuery {
        interval.historyQuery(lifetime: lifetime, now: now)
    }

    struct Outcome {
        let tokenId: String
        let title: String
        let probability: Decimal?
        let color: PolymarketProbabilityChart.SeriesColor
    }

    private struct PickedOutcome {
        let sourceIndex: Int
        let marketID: String
        let title: String
        let outcome: PolymarketOutcome
        let startDate: Date?
        let endDate: Date?
        let closedDate: Date?
    }
}

// MARK: - Domain mapping

extension PolymarketEventChartContent {
    static func make(
        event: PolymarketEvent,
        marketIDs: [String],
        sports: PolymarketEventSports?,
        now: Date = Date()
    ) -> Self? {
        let markets = chartedMarkets(event.markets.ordered(by: marketIDs), sports: sports)
        let picked = pickedOutcomes(markets: markets)
        let drawMarketID = event.moneyline(in: markets)?.draw?.market.id

        guard picked.count >= MappingConstants.minimumSeriesCount else {
            return nil
        }

        let lifetime = PolymarketMarketLifetime(
            start: picked.compactMap(\.startDate).min() ?? event.startDate,
            status: lifetimeStatus(of: picked, in: event)
        )
        let intervals = PolymarketPriceInterval.available(marketAge: lifetime.age(at: now), isClosed: lifetime.isClosed)
        let initialInterval: PolymarketPriceInterval = event.isLive && intervals.contains(.hour) ? .hour : .allTime

        return Self(
            outcomes: picked.enumerated().map { index, item in
                Outcome(
                    tokenId: item.outcome.assetId,
                    title: item.title,
                    probability: item.outcome.probability,
                    color: color(of: item, seriesIndex: index, in: picked, drawMarketID: drawMarketID)
                )
            },
            intervals: intervals,
            initialInterval: initialInterval,
            lifetime: lifetime,
            isLive: event.isLive,
            isComplementaryPair: picked.count == MappingConstants.complementaryPairCount
                && Set(picked.map(\.marketID)).count == 1
        )
    }

    private static func lifetimeStatus(of picked: [PickedOutcome], in event: PolymarketEvent) -> PolymarketMarketLifetime.Status {
        guard event.status.isClosed else { return .open }

        return .closed(
            closedDate: picked.compactMap(\.closedDate).max(),
            scheduledEndDate: picked.compactMap(\.endDate).max() ?? event.endDate
        )
    }

    private static func chartedMarkets(_ markets: [PolymarketMarket], sports: PolymarketEventSports?) -> [PolymarketMarket] {
        guard let sports, sports.isSports else { return markets }

        let moneyline = markets.filter { market in
            market.conditionId.map { sports.moneylineConditionIds.contains($0.lowercased()) } ?? false
        }

        return moneyline.isEmpty ? markets : moneyline
    }

    private static func pickedOutcomes(markets: [PolymarketMarket]) -> [PickedOutcome] {
        let candidates = markets.flatMap { market in
            pickableOutcomes(of: market).map { (market: market, pickable: $0) }
        }

        let picked = candidates
            .enumerated()
            .map { index, candidate in
                PickedOutcome(
                    sourceIndex: index,
                    marketID: candidate.market.id,
                    title: candidate.pickable.title,
                    outcome: candidate.pickable.outcome,
                    startDate: candidate.market.startDate,
                    endDate: candidate.market.endDate,
                    closedDate: candidate.market.closedDate
                )
            }
            .sorted { lhs, rhs in
                let left = lhs.outcome.probability ?? 0
                let right = rhs.outcome.probability ?? 0

                return left == right ? lhs.sourceIndex < rhs.sourceIndex : left > right
            }
            .prefix(MappingConstants.maximumSeriesCount)

        return Array(picked)
    }

    private static func pickableOutcomes(of market: PolymarketMarket) -> [(title: String, outcome: PolymarketOutcome)] {
        guard market.hasGenericOutcomes else {
            return market.outcomes.map { (title: $0.title, outcome: $0) }
        }

        return market.outcomes.first.map { [(title: market.groupItemTitle?.nilIfEmpty ?? $0.title, outcome: $0)] } ?? []
    }

    private static func color(
        of item: PickedOutcome,
        seriesIndex: Int,
        in picked: [PickedOutcome],
        drawMarketID: String?
    ) -> PolymarketProbabilityChart.SeriesColor {
        let isDraw: (PickedOutcome) -> Bool = { $0.marketID == drawMarketID }
        let sides = picked.filter { !isDraw($0) }

        guard sides.count == MappingConstants.outcomeStyledSeriesCount, picked.count - sides.count <= 1 else {
            return PolymarketProbabilityChart.color(forSeriesAt: seriesIndex)
        }

        guard !isDraw(item) else {
            return .draw
        }

        let order = sides.map(\.sourceIndex).sorted().firstIndex(of: item.sourceIndex) ?? 0

        return PolymarketOutcomeStyle(outcomeIndex: order).chartColor
    }
}

// MARK: - Series mapping

extension PolymarketEventChartContent {
    func series(from history: [String: [PolymarketPricePoint]]) -> [PolymarketProbabilityChart.Series] {
        let candidates = outcomes.map { outcome in
            PolymarketProbabilityChart.Series(
                id: outcome.tokenId,
                title: outcome.title,
                probabilityText: PolymarketPriceFormatter.percentText(outcome.probability),
                color: outcome.color,
                points: (history[outcome.tokenId] ?? []).chartPoints
            )
        }

        let series = filledIn(complemented(candidates)).filter { $0.points.count >= MappingConstants.minimumPointCount }

        guard series.count < MappingConstants.minimumSeriesCount else {
            return series
        }

        return candidates.map { candidate in
            PolymarketProbabilityChart.Series(
                id: candidate.id,
                title: candidate.title,
                probabilityText: candidate.probabilityText,
                color: candidate.color,
                points: []
            )
        }
    }

    func refreshed(from event: PolymarketEvent) -> Self {
        var latest: [String: Decimal] = [:]

        for outcome in event.markets.flatMap(\.outcomes) where latest[outcome.assetId] == nil {
            guard let probability = outcome.probability else { continue }

            latest[outcome.assetId] = probability
        }

        return Self(
            outcomes: outcomes.map {
                Outcome(
                    tokenId: $0.tokenId,
                    title: $0.title,
                    probability: latest[$0.tokenId] ?? $0.probability,
                    color: $0.color
                )
            },
            intervals: intervals,
            initialInterval: initialInterval,
            lifetime: lifetime,
            isLive: event.isLive,
            isComplementaryPair: isComplementaryPair
        )
    }

    func complemented(_ series: [PolymarketProbabilityChart.Series]) -> [PolymarketProbabilityChart.Series] {
        guard isComplementaryPair, series.count == MappingConstants.complementaryPairCount else { return series }

        return series.indices.map { index in
            let own = series[index]
            let other = series[1 - index]
            let mirrored: (PolymarketProbabilityChart.Point) -> PolymarketProbabilityChart.Point = {
                PolymarketProbabilityChart.Point(date: $0.date, probability: 1 - $0.probability)
            }

            guard let first = own.points.first, let last = own.points.last else {
                return PolymarketProbabilityChart.Series(
                    id: own.id,
                    title: own.title,
                    probabilityText: own.probabilityText,
                    color: own.color,
                    points: other.points.map(mirrored)
                )
            }

            let before = other.points.filter { $0.date < first.date }.map(mirrored)
            let after = other.points.filter { $0.date > last.date }.map(mirrored)

            return PolymarketProbabilityChart.Series(
                id: own.id,
                title: own.title,
                probabilityText: own.probabilityText,
                color: own.color,
                points: before + own.points + after
            )
        }
    }

    func filledIn(_ series: [PolymarketProbabilityChart.Series]) -> [PolymarketProbabilityChart.Series] {
        let drawn = series.filter { $0.points.count >= MappingConstants.minimumPointCount }

        guard
            drawn.count < series.count,
            let start = drawn.compactMap(\.points.first?.date).min(),
            let end = drawn.compactMap(\.points.last?.date).max(),
            end > start
        else {
            return series
        }

        return series.map { line in
            guard
                line.points.count < MappingConstants.minimumPointCount,
                let probability = line.points.last?.probability ?? outcomes.first(where: { $0.tokenId == line.id })?.probability ?? nil
            else {
                return line
            }

            return PolymarketProbabilityChart.Series(
                id: line.id,
                title: line.title,
                probabilityText: line.probabilityText,
                color: line.color,
                points: [
                    PolymarketProbabilityChart.Point(date: start, probability: probability),
                    PolymarketProbabilityChart.Point(date: end, probability: probability),
                ]
            )
        }
    }

    func probabilityText(forTokenID tokenID: String) -> String {
        PolymarketPriceFormatter.percentText(outcomes.first { $0.tokenId == tokenID }?.probability ?? nil)
    }

    static func dateLabels(for series: [PolymarketProbabilityChart.Series]) -> [String] {
        let bounds = series.flatMap { [$0.points.first?.date, $0.points.last?.date] }.compactMap { $0 }

        guard let start = bounds.min(), let end = bounds.max(), end > start else { return [] }

        let span = end.timeIntervalSince(start)
        let formatter = dateLabelFormatter(span: span)
        let steps = MappingConstants.dateLabelCount - 1

        return (0 ... steps).map { step in
            formatter.string(from: start.addingTimeInterval(span * TimeInterval(step) / TimeInterval(steps)))
        }
    }

    static func showsLatestMarker(
        for series: [PolymarketProbabilityChart.Series],
        fidelityMinutes: Int,
        now: Date = Date()
    ) -> Bool {
        guard let latest = series.compactMap({ $0.points.last?.date }).max() else { return false }

        return now.timeIntervalSince(latest) <= bucketDuration(fidelityMinutes: fidelityMinutes) * MappingConstants.staleBucketCount
    }

    private static func dateLabelFormatter(span: TimeInterval) -> DateFormatter {
        if span < MappingConstants.day {
            MappingConstants.timeFormatter
        } else if span < MappingConstants.day * MappingConstants.dayLabelsMaximumSpanDays {
            MappingConstants.dayFormatter
        } else {
            MappingConstants.monthFormatter
        }
    }
}

// MARK: - Live points

extension PolymarketEventChartContent {
    typealias LivePoints = [String: [PolymarketProbabilityChart.Point]]

    func recordingLivePoints(_ livePoints: LivePoints, interval: PolymarketPriceInterval, at date: Date) -> LivePoints {
        guard !lifetime.isClosed else { return [:] }

        var recorded = livePoints

        for outcome in outcomes {
            guard let probability = outcome.probability else { continue }

            let point = PolymarketProbabilityChart.Point(date: date, probability: probability)

            if streamsLivePoints(on: interval) {
                recorded[outcome.tokenId, default: []].append(point)
            } else {
                recorded[outcome.tokenId] = [point]
            }
        }

        return recorded
    }

    static func seriesWithLivePoints(
        _ series: [PolymarketProbabilityChart.Series],
        livePoints: LivePoints,
        interval: PolymarketPriceInterval,
        now: Date
    ) -> [PolymarketProbabilityChart.Series] {
        let cutoff = interval.duration.map { now.addingTimeInterval(-$0) }

        return series.map { series in
            let lastDate = series.points.last?.date ?? .distantPast
            let live = livePoints[series.id] ?? []
            var tail = live.filter { $0.date > lastDate }

            if tail.isEmpty, let latest = live.last {
                tail = [PolymarketProbabilityChart.Point(date: lastDate.addingTimeInterval(1), probability: latest.probability)]
            }

            let points = (series.points + tail).filter { point in cutoff.map { point.date >= $0 } ?? true }

            return PolymarketProbabilityChart.Series(
                id: series.id,
                title: series.title,
                probabilityText: series.probabilityText,
                color: series.color,
                points: points.count >= MappingConstants.minimumPointCount ? points : series.points
            )
        }
    }

    static func isOutdated(since date: Date, fidelityMinutes: Int, now: Date) -> Bool {
        now.timeIntervalSince(date) >= bucketDuration(fidelityMinutes: fidelityMinutes)
    }

    private static func bucketDuration(fidelityMinutes: Int) -> TimeInterval {
        TimeInterval(fidelityMinutes) * MappingConstants.minute
    }
}

// MARK: - Period titles

private extension PolymarketPriceInterval {
    // [REDACTED_TODO_COMMENT]
    func title(isLive: Bool) -> String {
        switch self {
        case .hour: isLive ? "Live" : "1h"
        case .sixHours: "6h"
        case .day: "1d"
        case .week: "1w"
        case .month: "1m"
        case .allTime: "Max"
        }
    }
}

// MARK: - Market ordering

private extension PolymarketMarket {
    var hasGenericOutcomes: Bool {
        Set(outcomes.map { $0.title.lowercased() }) == PolymarketEventChartContent.MappingConstants.genericOutcomes
    }
}

private extension [PolymarketMarket] {
    func ordered(by ids: [String]) -> [PolymarketMarket] {
        let marketsByID = Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return ids.compactMap { marketsByID[$0] }
    }
}

// MARK: - Points

private extension [PolymarketPricePoint] {
    var chartPoints: [PolymarketProbabilityChart.Point] {
        map { PolymarketProbabilityChart.Point(date: $0.date, probability: $0.probability) }
    }
}

// MARK: - Constants

private extension PolymarketEventChartContent {
    enum MappingConstants {
        static let minimumSeriesCount = 1
        static let maximumSeriesCount = 4
        static let outcomeStyledSeriesCount = 2
        static let complementaryPairCount = 2
        static let minimumPointCount = 2
        static let genericOutcomes: Set<String> = ["yes", "no"]
        static let dateLabelCount = 4
        static let minute: TimeInterval = 60
        static let day: TimeInterval = 24 * 60 * 60
        static let dayLabelsMaximumSpanDays: TimeInterval = 60
        static let staleBucketCount: TimeInterval = 2

        static let timeFormatter = makeFormatter(template: "jmm")
        static let dayFormatter = makeFormatter(template: "MMMd")
        static let monthFormatter = makeFormatter(template: "MMM")

        private static func makeFormatter(template: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate(template)
            return formatter
        }
    }
}
