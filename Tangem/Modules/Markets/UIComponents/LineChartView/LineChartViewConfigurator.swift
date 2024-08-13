//
//  LineChartViewConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import DGCharts

struct LineChartViewConfigurator {
    let chartData: LineChartViewData

    func configure(_ chartView: LineChartViewWrapper.UIViewType) {
        let dataSet = makeDataSet()
        chartView.data = LineChartData(dataSet: dataSet)

        configureYAxis(on: chartView, using: chartData.yAxis)
        configureXAxis(on: chartView, using: chartData.xAxis)
    }

    private func configureYAxis(on chartView: LineChartViewWrapper.UIViewType, using yAxisData: LineChartViewData.YAxis) {
        chartView.leftAxis.setLabelCount(yAxisData.labelCount, force: true)
        // We're losing some precision here due to the `Decimal` -> `Double` conversion,
        // but that's ok - graphical charts are never 100% accurate by design
        // [REDACTED_TODO_COMMENT]
        chartView.leftAxis.axisMinimum = yAxisData.axisMinValue.doubleValue
        chartView.leftAxis.axisMaximum = yAxisData.axisMaxValue.doubleValue
    }

    private func configureXAxis(on chartView: LineChartViewWrapper.UIViewType, using xAxisData: LineChartViewData.XAxis) {
        chartView.xAxis.setLabelCount(xAxisData.labelCount, force: true)
        // We're losing some precision here due to the `Decimal` -> `Double` conversion,
        // but that's ok - graphical charts are never 100% accurate by design
        // [REDACTED_TODO_COMMENT]
        /*
         chartView.xAxis.axisMinimum = xAxisData.axisMinValue.doubleValue
         chartView.xAxis.axisMaximum = xAxisData.axisMaxValue.doubleValue
          */
    }

    private func makeDataSet() -> LineChartDataSet {
        let utility = LineChartViewUtility()
        let chartColor = utility.selectedChartLineColor(for: chartData.trend)
        let chartFill = utility.selectedChartFillGradient(for: chartData.trend)

        let chartDataEntries = chartData.xAxis.values.map { value in
            return ChartDataEntry(x: value.timeStamp.doubleValue, y: value.price.doubleValue, data: value)
        }

        let dataSet = ColorSplitLineChartDataSet(entries: chartDataEntries)
        dataSet.fillAlpha = 1.0
        dataSet.fill = chartFill
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineCapType = .round
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.verticalHighlightIndicatorInset = -8.0
        dataSet.setColor(chartColor)

        // [REDACTED_TODO_COMMENT]
        /*
         dataSet.mode = .cubicBezier
         dataSet.cubicIntensity = 0.08
         */

        dataSet.highlightLineWidth = 1.0
        dataSet.highlightLineDashLengths = [6.0, 2.0]
        dataSet.highlightLineDashPhase = 3.0
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.highlightColor = chartColor */

        dataSet.drawHighlightCircleEnabled = true
        dataSet.highlightCircleHoleRadius = 2.0

        dataSet.innerHighlightCircleRadius = 5.0
        dataSet.innerHighlightCircleAlpha = 1.0
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.innerHighlightCircleColor = chartColor */

        dataSet.outerHighlightCircleRadius = 8.0
        dataSet.outerHighlightCircleAlpha = 0.24
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.outerHighlightCircleColor = chartColor */

        return dataSet
    }
}
