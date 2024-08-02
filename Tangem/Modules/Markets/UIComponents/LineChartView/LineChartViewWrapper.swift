//
//  LineChartViewWrapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import DGCharts

/// Wrapper for `DGCharts.LineChartView` view.
struct LineChartViewWrapper: UIViewRepresentable {
    typealias UIViewType = DGCharts.LineChartView
    typealias PriceInterval = MarketsPriceIntervalType

    let selectedPriceInterval: PriceInterval
    let chartData: LineChartViewData
    let onMake: (_ chartView: UIViewType) -> Void

    func makeUIView(context: Context) -> UIViewType {
        let coordinator = context.coordinator
        let chartView = UIViewType()
        let renderer = ColorSplitLineChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler
        )
        renderer.delegate = coordinator
        chartView.renderer = renderer
        chartView.delegate = coordinator
        chartView.xAxis.valueFormatter = coordinator.xAxisValueFormatter

        onMake(chartView)

        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(chartView)

        return chartView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(uiView)

        context.coordinator.setSelectedPriceInterval(selectedPriceInterval)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(view: self, selectedPriceInterval: selectedPriceInterval, chartFillAlpha: 1.0)
    }
}

// MARK: - Auxiliary types

extension LineChartViewWrapper {
    final class Coordinator {
        fileprivate var xAxisValueFormatter: AxisValueFormatter { _xAxisValueFormatter }

        private let _xAxisValueFormatter: MarketsHistoryChartXAxisValueFormatter
        private let view: LineChartViewWrapper
        private let chartFillAlpha: CGFloat

        fileprivate init(
            view: LineChartViewWrapper,
            selectedPriceInterval: PriceInterval,
            chartFillAlpha: CGFloat
        ) {
            self.view = view
            self.chartFillAlpha = chartFillAlpha
            _xAxisValueFormatter = MarketsHistoryChartXAxisValueFormatter(selectedPriceInterval: selectedPriceInterval)
        }

        fileprivate func setSelectedPriceInterval(_ interval: PriceInterval) {
            _xAxisValueFormatter.setSelectedPriceInterval(interval)
        }
    }
}

// MARK: - ChartViewDelegate protocol conformance

extension LineChartViewWrapper.Coordinator: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let lastValue = view.chartData.xAxis.values.last else {
            assertionFailure("Unable to last value for X axis")
            return
        }

        guard let selectedValue = entry.data as? LineChartViewData.Value else {
            assertionFailure("Unable to get value for selected chart data entry \(entry)")
            return
        }

        let utility = LineChartViewUtility()
        let chartTrend = utility.chartTrend(firstValue: selectedValue, lastValue: lastValue)
        let chartLineColor = utility.selectedChartLineColor(for: chartTrend)

        chartView.setColorSplitLineChartHighlightColor(chartLineColor)
    }

    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.drawVerticalHighlightIndicatorEnabled = false
        chartView.clearHighlights()
    }

    func chartViewDidReceiveTouches(_ chartView: ChartViewBase) {
        chartView.drawVerticalHighlightIndicatorEnabled = true
    }

    func chartViewDidEndTouches(_ chartView: ChartViewBase) {
        guard let chartView = chartView as? LineChartViewWrapper.UIViewType else {
            return
        }

        // If there is an active pan gesture in the chart view (i.e. `isPanGestureBegan` equals true),
        // vertical highlight indicator will be disabled in the `chartViewDidEndPanning(_:)` method call
        if !chartView.isPanGestureBegan {
            chartView.drawVerticalHighlightIndicatorEnabled = false
            chartView.clearHighlights()
        }
    }

    func chartViewDidCancelTouches(_ chartView: ChartViewBase) {
        guard let chartView = chartView as? LineChartViewWrapper.UIViewType else {
            return
        }

        // If there is an active pan gesture in the chart view (i.e. `isPanGestureBegan` equals true),
        // vertical highlight indicator will be disabled in the `chartViewDidEndPanning(_:)` method call
        if !chartView.isPanGestureBegan {
            chartView.drawVerticalHighlightIndicatorEnabled = false
            chartView.clearHighlights()
        }
    }
}

// MARK: - ColorSplitLineChartRendererDelegate protocol conformance

extension LineChartViewWrapper.Coordinator: ColorSplitLineChartRendererDelegate {
    func segmentAppearanceBefore(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance? {
        let utility = LineChartViewUtility()
        let chartLineColor = utility.inactiveChartLineColor()
        let chartFill = utility.inactiveChartFillGradient()

        return ColorSplitLineChartSegmentAppearance(
            fill: chartFill,
            fillAlpha: chartFillAlpha,
            lineColor: chartLineColor
        )
    }

    func segmentAppearanceAfter(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance? {
        guard let lastValue = view.chartData.xAxis.values.last else {
            assertionFailure("Unable to last value for X axis")
            return nil
        }

        guard let highlightedValue = highlightedEntry.data as? LineChartViewData.Value else {
            assertionFailure("Unable to get value for highlighted chart data entry \(highlightedEntry)")
            return nil
        }

        let utility = LineChartViewUtility()
        let chartTrend = utility.chartTrend(firstValue: highlightedValue, lastValue: lastValue)
        let chartLineColor = utility.selectedChartLineColor(for: chartTrend)
        let chartFill = utility.selectedChartFillGradient(for: chartTrend)

        return ColorSplitLineChartSegmentAppearance(
            fill: chartFill,
            fillAlpha: chartFillAlpha,
            lineColor: chartLineColor
        )
    }
}
