//
//  YieldModulePreiOS16Chart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import DGCharts

struct YieldModuleDGChartContainer: View {
    let state: YieldModuleChart.State

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .infinityFrame(alignment: .center)
        case .loaded(let data, let xLabels, let average):
            YieldModuleDGChart(months: xLabels, aprValues: data, averageApy: average)
        }
    }
}

struct YieldModuleDGChart: UIViewRepresentable {
    // MARK: - Properties

    private let months: [String]
    private let aprValues: [Double]
    private let averageApy: Double?

    // MARK: - Init

    init(months: [String], aprValues: [Double], averageApy: Double?) {
        self.months = months
        self.aprValues = aprValues
        self.averageApy = averageApy
    }

    func makeUIView(context: Context) -> BarChartView {
        let chart = BarChartView()
        setData(for: chart)

        if let averageApy {
            addAverageLine(to: chart, average: averageApy)
        }

        configureChart(chart)
        configureXAxis(for: chart, months: months)
        configureYAxis(for: chart)
        return chart
    }

    func updateUIView(_ uiView: BarChartView, context: Context) {}

    private func configureChart(_ chart: BarChartView) {
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.pinchZoomEnabled = false
        chart.scaleYEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.fitBars = true
        chart.notifyDataSetChanged()
    }

    private func addAverageLine(to chart: BarChartView, average: Double) {
        let avgLine = ChartLimitLine(limit: average)
        avgLine.lineWidth = 1
        avgLine.lineDashLengths = [4, 4]
        avgLine.lineColor = .black

        avgLine.label = Localization.yieldModuleRateInfoSheetChartAverage(String(format: "%.2f", average) + "%")
        avgLine.valueTextColor = UIColor.textPrimary1
        avgLine.valueFont = UIFonts.Regular.caption2
        avgLine.labelPosition = .leftTop

        chart.leftAxis.addLimitLine(avgLine)
    }

    private func setData(for chart: BarChartView) {
        let entries = aprValues.enumerated().map { BarChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = BarChartDataSet(entries: entries, label: "Supply APR")

        set.drawValuesEnabled = false
        set.colors = [.iconAccent]

        let data = BarChartData(dataSet: set)
        data.barWidth = 0.6
        chart.data = data
    }

    private func configureYAxis(for chart: BarChartView) {
        let y = chart.leftAxis
        y.axisMinimum = 0
        y.axisMaximum = 10
        y.granularity = 3
        y.labelFont = UIFonts.Regular.caption2
        y.labelTextColor = .textTertiary
        y.valueFormatter = DefaultAxisValueFormatter { value, _ in String(format: "%.0f%%", value) }
        y.axisLineColor = .clear
        y.gridColor = UIColor.label.withAlphaComponent(0.1)
    }

    private func configureXAxis(for chart: BarChartView, months: [String]) {
        let x = chart.xAxis
        x.labelPosition = .bottom
        x.labelFont = UIFonts.Regular.caption2
        x.labelTextColor = .textTertiary
        x.axisLineColor = .clear
        x.gridColor = UIColor.label.withAlphaComponent(0.1)

        x.labelPosition = .bottom
        x.labelFont = UIFonts.Regular.caption2
        x.labelTextColor = .textTertiary
        x.drawGridLinesEnabled = false
        x.setLabelCount(5, force: true)
        x.valueFormatter = AxisFiveLabelsFormatter(labels: months)
    }
}

final class AxisFiveLabelsFormatter: AxisValueFormatter {
    private let labels: [String]

    init(labels: [String]) { self.labels = labels }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard labels.count == 5, let axis = axis, axis.axisMaximum > axis.axisMinimum else { return "" }
        let t = (value - axis.axisMinimum) / (axis.axisMaximum - axis.axisMinimum)
        let idx = max(0, min(4, Int(round(t * 4))))
        return labels[idx]
    }
}
