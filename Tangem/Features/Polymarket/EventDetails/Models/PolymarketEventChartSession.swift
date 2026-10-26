//
//  PolymarketEventChartSession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

struct PolymarketEventChartSession {
    private(set) var content: PolymarketEventChartContent
    private(set) var selectedInterval: PolymarketPriceInterval
    private(set) var displayedHistory: History?
    private(set) var loadingInterval: PolymarketPriceInterval?

    private var historyCache: [PolymarketPriceInterval: History] = [:]
    private var livePoints: PolymarketEventChartContent.LivePoints = [:]
    private var showsStaleHistory = false

    init(content: PolymarketEventChartContent) {
        self.content = content
        selectedInterval = content.initialInterval
    }

    var isLoadingHistory: Bool {
        loadingInterval != nil
    }

    struct History {
        let interval: PolymarketPriceInterval
        let series: [PolymarketProbabilityChart.Series]
        let dateLabels: [String]
        let fidelityMinutes: Int
        let loadedAt: Date
    }
}

// MARK: - Changes

extension PolymarketEventChartSession {
    mutating func startLoading(_ interval: PolymarketPriceInterval) {
        loadingInterval = interval
    }

    mutating func selectPeriod(_ interval: PolymarketPriceInterval, now: Date) -> Bool {
        guard interval != selectedInterval, content.intervals.contains(interval) else {
            return false
        }

        selectedInterval = interval

        if let cached = historyCache[interval] {
            displayedHistory = cached
            livePoints = content.recordingLivePoints([:], interval: interval, at: now)
            showsStaleHistory = false
        } else {
            showsStaleHistory = displayedHistory != nil
        }

        loadingInterval = interval
        return true
    }

    mutating func applyHistory(
        _ history: [String: [PolymarketPricePoint]]?,
        interval: PolymarketPriceInterval,
        fidelityMinutes: Int,
        now: Date
    ) {
        guard interval == loadingInterval else { return }

        loadingInterval = nil
        showsStaleHistory = false

        guard let history else {
            selectedInterval = displayedHistory?.interval ?? selectedInterval
            return
        }

        let series = content.series(from: history)
        let loaded = History(
            interval: interval,
            series: series,
            dateLabels: PolymarketEventChartContent.dateLabels(for: series),
            fidelityMinutes: fidelityMinutes,
            loadedAt: now
        )

        historyCache[interval] = loaded
        displayedHistory = loaded
        livePoints = content.recordingLivePoints([:], interval: interval, at: now)
    }

    mutating func refresh(with event: PolymarketEvent, now: Date) -> Bool {
        guard !isLoadingHistory else { return false }

        content = content.refreshed(from: event)

        guard let displayedHistory else { return false }

        let interval = displayedHistory.interval
        let isStreaming = content.streamsLivePoints(on: interval)
        let lastUpdate = isStreaming ? livePoints.values.compactMap(\.last?.date).max() ?? displayedHistory.loadedAt : displayedHistory.loadedAt
        let isOutdated = PolymarketEventChartContent.isOutdated(
            since: lastUpdate,
            fidelityMinutes: displayedHistory.fidelityMinutes,
            now: now
        )

        if isStreaming, isOutdated {
            livePoints = [:]
            showsStaleHistory = true
        } else {
            livePoints = content.recordingLivePoints(livePoints, interval: interval, at: now)
        }

        guard isOutdated else { return false }

        loadingInterval = interval
        return true
    }
}

// MARK: - Display

extension PolymarketEventChartSession {
    func chartModel(
        now: Date,
        legendLineCount: Int,
        animatesChanges: Bool,
        onSelectPeriod: @escaping (String) -> Void
    ) -> PolymarketProbabilityChart.Model? {
        guard let history = displayedHistory else { return nil }

        let series = PolymarketEventChartContent.seriesWithLivePoints(
            history.series,
            livePoints: livePoints,
            interval: history.interval,
            now: now
        )
        let hasLivePoints = !livePoints.isEmpty
        let showsLatestMarker = hasLivePoints || PolymarketEventChartContent.showsLatestMarker(
            for: history.series,
            fidelityMinutes: history.fidelityMinutes,
            now: now
        )
        let latestMarker: PolymarketProbabilityChart.LatestMarker = switch (showsLatestMarker, content.streamsLivePoints(on: history.interval)) {
        case (false, _): .hidden
        case (true, false): .still
        case (true, true): .pulsing
        }

        return PolymarketProbabilityChart.Model(
            series: series.map { series in
                PolymarketProbabilityChart.Series(
                    id: series.id,
                    title: series.title,
                    probabilityText: content.probabilityText(forTokenID: series.id),
                    color: series.color,
                    points: series.points
                )
            },
            dateLabels: hasLivePoints ? PolymarketEventChartContent.dateLabels(for: series) : history.dateLabels,
            periods: PolymarketProbabilityChart.Periods(items: content.periods, selectedID: selectedInterval.rawValue),
            isLoading: showsStaleHistory,
            latestMarker: latestMarker,
            legendLineCount: legendLineCount,
            animatesChanges: animatesChanges,
            probabilityText: { PolymarketPriceFormatter.percentText($0) },
            onSelectPeriod: onSelectPeriod
        )
    }
}
