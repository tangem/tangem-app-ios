//
//  EarnCalculatorChart.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Charts
import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

struct EarnCalculatorChart: View {
    let bars: [EarnCalculatorViewState.Bar]
    @Binding var selectedBarID: EarnCalculatorViewState.Bar.ID?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        Chart {
            ForEach(bars) { bar in
                segment(for: bar, from: .zero, height: Constants.bottomSegmentHeight)
                    .foregroundStyle(DesignSystem.Color.bgAccentNeutral)
                    .opacity(opacity(for: bar))
                    .accessibilityHidden(true)

                segment(for: bar, from: valueSegmentStart, height: valueHeight(for: bar))
                    .foregroundStyle(DesignSystem.Color.bgStatusInfo)
                    .opacity(opacity(for: bar))
                    // [REDACTED_TODO_COMMENT]
                    .accessibilityLabel("Month \(bar.month)")
                    .accessibilityValue("\(bar.balance), \(bar.earned)")

                segment(for: bar, from: topSegmentStart(for: bar), height: Constants.topSegmentHeight)
                    .foregroundStyle(DesignSystem.Color.bgStatusInfoSubtle)
                    .opacity(opacity(for: bar))
                    .accessibilityHidden(true)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0 ... Double(Constants.chartHeight))
        .chartXAxis {
            AxisMarks(values: axisLabels.keys.sorted()) { value in
                if let id = value.as(Int.self), let label = axisLabels[id] {
                    AxisValueLabel(
                        anchor: id == bars.last?.id ? .topTrailing : nil,
                        collisionResolution: .disabled,
                        verticalSpacing: Constants.axisSpacing
                    ) {
                        Text(label)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in
            plot.frame(height: Constants.chartHeight)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                let plotFrame = geometry[proxy.plotAreaFrame]

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            toggleSelection(at: location.x - plotFrame.minX, proxy: proxy)
                        }

                    tooltip(proxy: proxy, plotFrame: plotFrame)
                }
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityHidden(true)
            }
        }
        // [REDACTED_TODO_COMMENT]
        .accessibilityLabel("Projected balance")
        .accessibilityIdentifier(EarnCalculatorAccessibilityIdentifiers.chart)
    }
}

// MARK: - Subviews

private extension EarnCalculatorChart {
    func segment(for bar: EarnCalculatorViewState.Bar, from start: CGFloat, height: CGFloat) -> some ChartContent {
        BarMark(
            x: .value("Bar", bar.id),
            yStart: .value("Start", Double(start)),
            yEnd: .value("End", Double(start + height)),
            width: .fixed(Constants.barWidth)
        )
        .cornerRadius(Constants.barWidth / 2)
    }

    @ViewBuilder
    func tooltip(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        if let bar = selectedBar,
           let centerX = proxy.position(forX: Double(bar.id)),
           let columnTop = proxy.position(forY: Double(columnHeight(for: bar))) {
            let anchor = TooltipAnchor(
                center: plotFrame.minX + centerX,
                columnTop: plotFrame.minY + columnTop,
                plotFrame: plotFrame
            )

            tooltipSurface {
                VStack(alignment: .leading, spacing: .zero) {
                    Text(bar.balance)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(bar.earned)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textBrand)
                }
                .padding(.horizontal, Constants.tooltipHorizontalPadding)
                .padding(.vertical, Constants.tooltipVerticalPadding)
                .environment(\.layoutDirection, layoutDirection)
            }
            .fixedSize()
            .alignmentGuide(.leading) { dimensions in
                -tooltipLeading(anchor: anchor, tooltipSize: dimensions)
            }
            .alignmentGuide(.top) { dimensions in
                -tooltipTop(anchor: anchor, tooltipSize: dimensions)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    func tooltipSurface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Constants.tooltipCornerRadius)

        if reduceTransparency {
            content().background(DesignSystem.Color.materialModalFillSolid, in: shape)
        } else {
            content().tangemMaterialSurface(in: shape)
        }
    }
}

// MARK: - Tooltip Placement

private extension EarnCalculatorChart {
    struct TooltipAnchor {
        let center: CGFloat
        let columnTop: CGFloat
        let plotFrame: CGRect
    }

    func fitsAboveColumn(anchor: TooltipAnchor, tooltipHeight: CGFloat) -> Bool {
        anchor.columnTop - tooltipHeight - Constants.tooltipSpacing >= anchor.plotFrame.minY
    }

    func tooltipTop(anchor: TooltipAnchor, tooltipSize: ViewDimensions) -> CGFloat {
        guard fitsAboveColumn(anchor: anchor, tooltipHeight: tooltipSize.height) else {
            return anchor.plotFrame.minY
        }

        return anchor.columnTop - tooltipSize.height - Constants.tooltipSpacing
    }

    func tooltipLeading(anchor: TooltipAnchor, tooltipSize: ViewDimensions) -> CGFloat {
        let leading: CGFloat

        if fitsAboveColumn(anchor: anchor, tooltipHeight: tooltipSize.height) {
            leading = anchor.center - tooltipSize.width / 2
        } else if anchor.center > anchor.plotFrame.midX {
            leading = anchor.center - Constants.barWidth / 2 - Constants.tooltipSpacing - tooltipSize.width
        } else {
            leading = anchor.center + Constants.barWidth / 2 + Constants.tooltipSpacing
        }

        return clamp(leading, min: anchor.plotFrame.minX, max: anchor.plotFrame.maxX - tooltipSize.width)
    }
}

// MARK: - Layout

private extension EarnCalculatorChart {
    var selectedBar: EarnCalculatorViewState.Bar? {
        bars.first { $0.id == selectedBarID }
    }

    var axisLabels: [EarnCalculatorViewState.Bar.ID: String] {
        bars.reduce(into: [:]) { labels, bar in
            labels[bar.id] = bar.axisLabel
        }
    }

    var xDomain: ClosedRange<Double> {
        -Constants.xDomainInset ... Double(max(bars.count, 1)) - Constants.xDomainInset
    }

    var valueSegmentStart: CGFloat {
        Constants.bottomSegmentHeight + Constants.segmentSpacing
    }

    func topSegmentStart(for bar: EarnCalculatorViewState.Bar) -> CGFloat {
        valueSegmentStart + valueHeight(for: bar) + Constants.segmentSpacing
    }

    func opacity(for bar: EarnCalculatorViewState.Bar) -> Double {
        selectedBarID != nil && selectedBarID != bar.id ? Constants.dimmedOpacity : 1
    }

    func valueHeight(for bar: EarnCalculatorViewState.Bar) -> CGFloat {
        max(CGFloat(bar.normalizedHeight) * Constants.maxValueSegmentHeight, Constants.barWidth)
    }

    func columnHeight(for bar: EarnCalculatorViewState.Bar) -> CGFloat {
        topSegmentStart(for: bar) + Constants.topSegmentHeight
    }

    func toggleSelection(at x: CGFloat, proxy: ChartProxy) {
        guard !bars.isEmpty, let value = proxy.value(atX: x, as: Double.self) else {
            return
        }

        let index = clamp(Int(value.rounded()), min: 0, max: bars.count - 1)

        guard let bar = bars[safe: index] else {
            return
        }

        withAnimation(.easeInOut(duration: Constants.selectionAnimationDuration)) {
            selectedBarID = selectedBarID == bar.id ? nil : bar.id
        }
    }
}

// MARK: - Constants

private extension EarnCalculatorChart {
    enum Constants {
        static let chartHeight: CGFloat = 137
        static let axisSpacing: CGFloat = 16
        static let barWidth: CGFloat = 4
        static let segmentSpacing: CGFloat = 2
        static let topSegmentHeight: CGFloat = 17
        static let bottomSegmentHeight: CGFloat = 10
        static let maxValueSegmentHeight: CGFloat = chartHeight - topSegmentHeight - bottomSegmentHeight - segmentSpacing * 2
        static let xDomainInset: Double = 0.5
        static let dimmedOpacity: Double = 0.4
        static let tooltipHorizontalPadding: CGFloat = 12
        static let tooltipVerticalPadding: CGFloat = 6
        static let tooltipCornerRadius: CGFloat = 14
        static let tooltipSpacing: CGFloat = 4
        static let selectionAnimationDuration: TimeInterval = 0.2
    }
}
