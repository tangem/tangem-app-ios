//
//  MarketsHistoryChartView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsHistoryChartView: View {
    @ObservedObject var viewModel: MarketsHistoryChartViewModel

    var body: some View {
        ZStack {
            Group {
                switch viewModel.viewState {
                case .idle:
                    EmptyView()

                case .loading(let previousData):
                    makeLoadingView(for: previousData)

                case .loaded(let chartData):
                    makeChartView(for: chartData)

                case .noData:
                    noDataView

                case .failed:
                    TangemUnableToLoadDataView(
                        isButtonBusy: false,
                        retryButtonAction: viewModel.reload
                    )
                }
            }
            .transition(.opacity)
        }
        // Legacy value, reason unknown
        // Perhaps connected with UIKit-nature of DGCharts
        .frame(height: 192.0)
        .animation(.linear(duration: 0.2), value: viewModel.viewState)
        .allowsHitTesting(viewModel.allowsHitTesting)
        .onAppear(perform: viewModel.onViewAppear)
    }

    private var standaloneLoadingView: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }

    private var noDataView: some View {
        Text(Localization.marketsLoadingNoDataTitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    private var overlayLoadingView: some View {
        Color.clear
            .overlay {
                let overlayColor = DesignSystem.Color.bgPrimary
                    .opacity(2.0 / 3.0)

                LinearGradient(
                    colors: [
                        .clear,
                        overlayColor,
                        overlayColor,
                        overlayColor,
                        overlayColor,
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .padding(.vertical, -28.0)
            }
            .overlay {
                standaloneLoadingView
            }
    }

    @ViewBuilder
    private func makeLoadingView(for chartData: LineChartViewData?) -> some View {
        if let chartData {
            makeChartView(for: chartData)
                .overlay {
                    overlayLoadingView
                }
        } else {
            standaloneLoadingView
        }
    }

    @ViewBuilder
    private func makeChartView(for chartData: LineChartViewData) -> some View {
        LineChartViewWrapper(
            selectedPriceInterval: viewModel.selectedPriceInterval,
            chartData: chartData,
            onValueSelection: viewModel.onValueSelection,
            onViewMake: { chartView in
                configureCommon(chartView)
                configureAxes(chartView)
            }
        )
    }

    private func configureCommon(_ chartView: LineChartViewWrapper.UIViewType) {
        chartView.minOffset = 0.0
        chartView.extraTopOffset = 26.0
        chartView.dragYEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.highlightPerTapEnabled = false
        chartView.setScaleEnabled(false)
        chartView.clipDataToContentEnabled = false
        chartView.legend.enabled = false

        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelFont = Constants.labelFont
        chartView.xAxis.labelTextColor = Constants.labelTextColor
        chartView.xAxis.yOffset = 26.0
        chartView.xAxis.xOffset = 0.0
        chartView.xAxis.firstLastLabelYOffset = 4.0
        chartView.xAxis.avoidFirstLastClippingEnabled = true
    }

    private func configureAxes(_ chartView: LineChartViewWrapper.UIViewType) {
        let leftFormatter = MarketsHistoryChartYAxisLabelFormatter()
        let rightFormatter = MarketsHistoryChartYAxisMinMaxPriceFormatter()

        let insetRenderer = InsetGridLineYAxisRenderer(
            viewPortHandler: chartView.viewPortHandler,
            axis: chartView.leftAxis,
            transformer: chartView.getTransformer(forAxis: .left)
        )
        insetRenderer.labelOffset = Constants.labelOffset
        insetRenderer.labelFont = Constants.labelFont
        insetRenderer.leftAxisFormatter = leftFormatter
        insetRenderer.rightAxisFormatter = rightFormatter
        chartView.leftYAxisRenderer = insetRenderer

        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.gridLineWidth = Constants.gridLineWidth
        chartView.leftAxis.gridColor = Constants.gridLineColor
        chartView.leftAxis.labelPosition = .insideChart
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftAxis.labelFont = Constants.labelFont
        chartView.leftAxis.labelTextColor = Constants.labelTextColor
        chartView.leftAxis.xOffset = Constants.labelOffset
        chartView.leftAxis.valueFormatter = leftFormatter

        chartView.rightAxis.enabled = true
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.rightAxis.drawAxisLineEnabled = false
        chartView.rightAxis.labelPosition = .insideChart
        chartView.rightAxis.labelFont = Constants.labelFont
        chartView.rightAxis.labelTextColor = Constants.labelTextColor
        chartView.rightAxis.xOffset = Constants.labelOffset
        chartView.rightAxis.valueFormatter = rightFormatter
    }
}

// MARK: - Constants

private extension MarketsHistoryChartView {
    enum Constants {
        static let labelFont: UIFont = UIFonts.Regular.caption2
        static let labelTextColor: UIColor = .init(DesignSystem.Color.textSecondary)
        static let labelOffset: CGFloat = 12
        static let gridLineColor: UIColor = .init(DesignSystem.Color.borderTertiary)
        static let gridLineWidth: CGFloat = 1
    }
}

// MARK: - Previews

#Preview {
    let factory = FakeMarketsHistoryChartViewModelFactory()

    return VStack {
        MarketsHistoryChartView(viewModel: factory.makeAll())

        MarketsHistoryChartView(viewModel: factory.makeHalfYear())

        MarketsHistoryChartView(viewModel: factory.makeWeek())
    }
}
