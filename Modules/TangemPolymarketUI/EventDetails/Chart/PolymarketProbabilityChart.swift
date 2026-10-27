//
//  PolymarketProbabilityChart.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Charts
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

public struct PolymarketProbabilityChart: View {
    public static func skeleton(legendLineCount: Int = 2) -> Self {
        Self(model: nil, skeletonLegendLineCount: legendLineCount)
    }

    @GestureState private var scrub: Scrub?

    private let model: Model?
    private let skeletonLegendLineCount: Int

    public init(model: Model) {
        self.model = model
        skeletonLegendLineCount = model.legendLineCount
    }

    private init(model: Model?, skeletonLegendLineCount: Int) {
        self.model = model
        self.skeletonLegendLineCount = skeletonLegendLineCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            legend

            plot
                .padding(.top, Constants.legendBottomSpacing)

            periodPicker
                .padding(.top, Constants.periodPickerTopSpacing)
        }
        .animation(model?.animatesChanges == true ? Constants.updateAnimation : nil, value: model?.series)
    }

    // MARK: - Legend

    @ViewBuilder
    private var legend: some View {
        if let model, !model.hasNoData {
            WrappingHStack(
                alignment: .leading,
                horizontalSpacing: Constants.legendItemSpacing,
                verticalSpacing: Constants.legendLineSpacing
            ) {
                ForEach(model.series) { series in
                    legendItem(series, model: model)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Self.legendHeight(lineCount: model.legendLineCount), alignment: .topLeading)
        } else if model != nil {
            Color.clear
                .frame(height: Constants.labelHeight)
        } else {
            VStack(alignment: .leading, spacing: Constants.legendLineSpacing) {
                ForEach(Constants.skeletonLegendLines.prefix(skeletonLegendLineCount), id: \.self) { line in
                    HStack(spacing: Constants.legendItemSpacing) {
                        ForEach(line, id: \.self) { width in
                            skeletonBar(width: width)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(height: Constants.labelHeight)
                }
            }
        }
    }

    private static func legendHeight(lineCount: Int) -> CGFloat {
        let lines = CGFloat(max(lineCount, 1))

        return Constants.labelHeight * lines + Constants.legendLineSpacing * (lines - 1)
    }

    private func skeletonBar(width: CGFloat) -> some View {
        Shimmer().variant(.custom(width: width, height: Constants.skeletonBarHeight))
    }

    private func legendItem(_ series: Series, model: Model) -> some View {
        HStack(spacing: Constants.legendMarkerSpacing) {
            Circle()
                .fill(series.color.marker)
                .frame(size: .init(bothDimensions: Constants.legendMarkerSize))
                .frame(size: .init(bothDimensions: Constants.legendMarkerSlotSize))

            HStack(spacing: Constants.legendTextSpacing) {
                Text(readOut(of: series, model: model))
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(series.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(minHeight: Constants.labelHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(series.title)
        .accessibilityValue(readOut(of: series, model: model))
    }

    private func readOut(of series: Series, model: Model) -> String {
        guard let scrubbedDate, let probability = series.probability(at: scrubbedDate) else {
            return series.probabilityText
        }

        return model.probabilityText(probability)
    }

    // MARK: - Plot

    @ViewBuilder
    private var plot: some View {
        if let model {
            if let scale = Scale(series: model.series) {
                loadedPlot(model: model, scale: scale)
                    .opacity(model.isLoading ? Constants.loadingOpacity : 1)
                    .allowsHitTesting(!model.isLoading)
            } else if model.isLoading {
                skeletonPlot
            } else {
                emptyPlot(model: model)
            }
        } else {
            skeletonPlot
        }
    }

    private var skeletonPlot: some View {
        HStack(alignment: .top, spacing: Constants.axisSpacing) {
            VStack(spacing: Constants.dateLabelsTopSpacing) {
                placeholderGrid
                    .overlay {
                        Shimmer()
                            .variant(.custom(height: Constants.plotHeight, cornerRadius: Constants.skeletonPlotRadius))
                    }

                HStack(spacing: 0) {
                    ForEach(indexed: Constants.skeletonDateLabelWidths, id: \.0) { index, width in
                        skeletonBar(width: width)

                        if index != Constants.skeletonDateLabelWidths.count - 1 {
                            Spacer(minLength: Constants.legendItemSpacing)
                        }
                    }
                }
                .frame(height: Constants.labelHeight)
            }

            VStack(alignment: .leading, spacing: Constants.placeholderRowSpacing) {
                ForEach(0 ..< Constants.tickCount, id: \.self) { _ in
                    skeletonBar(width: Constants.probabilityLabelWidth)
                }
            }
            .frame(width: Constants.probabilityLabelWidth, height: Constants.plotHeight, alignment: .top)
        }
        .accessibilityHidden(true)
    }

    private func emptyPlot(model: Model) -> some View {
        HStack(alignment: .top, spacing: Constants.axisSpacing) {
            VStack(spacing: Constants.dateLabelsTopSpacing) {
                placeholderGrid
                    .overlay { emptyState }

                Color.clear
                    .frame(height: Constants.labelHeight)
            }

            VStack(alignment: .leading, spacing: Constants.placeholderRowSpacing) {
                ForEach(Constants.placeholderTicks, id: \.self) { tick in
                    Text(model.probabilityText(tick))
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(height: Constants.labelHeight)
                }
            }
            .frame(width: Constants.probabilityLabelWidth, height: Constants.plotHeight, alignment: .topLeading)
            .dynamicTypeSize(...Constants.axisLabelMaximumTypeSize)
            .accessibilityHidden(true)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Constants.emptyStateSpacing) {
            DesignSystem.Icons.ChartLineVertical.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: Constants.emptyStateIconSize))
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .accessibilityHidden(true)

            // [REDACTED_TODO_COMMENT]
            Text("No data yet")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

            // [REDACTED_TODO_COMMENT]
            Text("The chart will appear after the first predictions")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Constants.emptyStateHorizontalPadding)
        .padding(.vertical, Constants.emptyStateVerticalPadding)
        .background(
            DesignSystem.Color.bgPrimary,
            in: RoundedRectangle(cornerRadius: Constants.emptyStateCornerRadius, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var placeholderGrid: some View {
        VStack(spacing: Constants.placeholderRowSpacing) {
            ForEach(0 ..< Constants.tickCount, id: \.self) { _ in
                gridLine
                    .frame(height: Constants.labelHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.plotHeight, alignment: .top)
    }

    private var gridLine: some View {
        DashedLine()
            .stroke(
                DesignSystem.Color.borderPrimary,
                style: StrokeStyle(lineWidth: Constants.gridLineWidth, dash: Constants.gridDash)
            )
    }

    private func loadedPlot(model: Model, scale: Scale) -> some View {
        HStack(alignment: .top, spacing: Constants.axisSpacing) {
            VStack(spacing: Constants.dateLabelsTopSpacing) {
                ZStack(alignment: .topLeading) {
                    grid(scale)

                    lines(model: model, scale: scale)

                    latestMarkerPulses(model: model, scale: scale)

                    scrubMarks(model: model, scale: scale)
                }
                .frame(height: Constants.plotHeight)
                .overlay { scrubber(scale, model: model) }

                dateLabels(model.dateLabels)
            }

            probabilityLabels(scale, text: model.probabilityText)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private func lines(model: Model, scale: Scale) -> some View {
        let chartLines = model.series.map(ProbabilityLines.Line.init)

        ProbabilityLines(
            lines: chartLines,
            scale: scale,
            showsLatestMarker: model.latestMarker != .hidden && scrubbedDate == nil,
            opacity: scrubbedDate == nil ? 1 : Constants.dimmedLineOpacity
        )
        .equatable()
        .accessibilityHidden(true)

        if let scrubbedDate {
            ProbabilityLines(lines: chartLines, scale: scale, showsLatestMarker: false, opacity: 1)
                .equatable()
                .clipShape(LeadingClip(fraction: scale.x(for: scrubbedDate, in: 1)))
                .accessibilityHidden(true)
        }
    }

    private func grid(_ scale: Scale) -> some View {
        GeometryReader { proxy in
            ForEach(indexed: scale.ticks, id: \.0) { _, tick in
                gridLine
                    .frame(height: Constants.gridLineWidth)
                    .offset(y: scale.y(for: tick, in: proxy.size.height) - Constants.gridLineWidth / 2)
            }
        }
    }

    // MARK: - Live

    @ViewBuilder
    private func latestMarkerPulses(model: Model, scale: Scale) -> some View {
        if model.latestMarker == .pulsing, scrubbedDate == nil {
            GeometryReader { proxy in
                ForEach(model.series) { series in
                    if let last = series.points.last {
                        LatestMarkerPulse(color: series.color.marker)
                            .offset(
                                x: scale.x(for: last.date, in: proxy.size.width) - Constants.markerDiameter / 2,
                                y: scale.y(for: last.probability.doubleValue, in: proxy.size.height) - Constants.markerDiameter / 2
                            )
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Scrubbing

    @ViewBuilder
    private func scrubMarks(model: Model, scale: Scale) -> some View {
        GeometryReader { proxy in
            if let scrubbedDate {
                let x = scale.x(for: scrubbedDate, in: proxy.size.width)

                ForEach(model.series) { series in
                    if let probability = series.probability(at: scrubbedDate) {
                        Circle()
                            .fill(series.color.marker)
                            .frame(size: .init(bothDimensions: Constants.markerDiameter))
                            .offset(
                                x: x - Constants.markerDiameter / 2,
                                y: scale.y(for: probability.doubleValue, in: proxy.size.height) - Constants.markerDiameter / 2
                            )
                    }
                }
            }
        }
    }

    private func scrubber(_ scale: Scale, model: Model) -> some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: Constants.scrubActivationDelay)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .updating($scrub) { value, scrub, _ in
                            guard case .second(true, let drag?) = value else { return }

                            let next = Scrub(x: drag.location.x, in: proxy.size.width, scale: scale, model: model)

                            if let step = next.step, step != scrub?.step {
                                FeedbackGenerator.selection()
                            }

                            scrub = next
                        }
                )
        }
    }

    private var scrubbedDate: Date? {
        scrub?.date
    }

    // MARK: - Axis labels

    private func probabilityLabels(_ scale: Scale, text: @escaping (Decimal) -> String) -> some View {
        GeometryReader { proxy in
            ForEach(indexed: scale.ticks, id: \.0) { _, tick in
                Text(text(Decimal(tick)))
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minHeight: Constants.labelHeight, alignment: .leading)
                    .offset(y: scale.y(for: tick, in: proxy.size.height) - Constants.labelHeight / 2)
            }
        }
        .frame(width: Constants.probabilityLabelWidth, height: Constants.plotHeight)
        .dynamicTypeSize(...Constants.axisLabelMaximumTypeSize)
        .accessibilityHidden(true)
    }

    private func dateLabels(_ labels: [String]) -> some View {
        HStack(spacing: 0) {
            ForEach(indexed: labels, id: \.0) { index, label in
                Text(label)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .fixedSize()

                if index != labels.count - 1 {
                    Spacer(minLength: Constants.legendItemSpacing)
                }
            }
        }
        .frame(minHeight: Constants.labelHeight)
        .dynamicTypeSize(...Constants.axisLabelMaximumTypeSize)
        .accessibilityHidden(true)
    }

    // MARK: - Periods

    @ViewBuilder
    private var periodPicker: some View {
        if model == nil {
            SegmentedControl(items: Constants.skeletonPeriods, selection: .constant(Constants.skeletonPeriods[0].id))
                .loading(true)
        } else if let model, let periods = model.periods, periods.items.count >= Constants.minimumPeriodCount {
            SegmentedControl(
                items: periods.items.map { SegmentedControl<String>.Item(id: $0.id, title: $0.title) },
                selection: Binding(
                    get: { periods.selectedID },
                    set: { model.onSelectPeriod($0) }
                )
            )
            .disabled(model.isLoading)
        }
    }
}

// MARK: - No data

private extension PolymarketProbabilityChart.Model {
    var hasNoData: Bool {
        !isLoading && PolymarketProbabilityChart.Scale(series: series) == nil
    }
}

// MARK: - Scrub

private extension PolymarketProbabilityChart {
    struct Scrub {
        let date: Date
        let step: Int?

        init(x: CGFloat, in width: CGFloat, scale: Scale, model: Model) {
            date = scale.date(atX: x, in: width)

            let pointCount = model.series.map(\.points.count).max() ?? 0

            guard width > 0, pointCount > 1 else {
                step = nil
                return
            }

            let spacing = max(width / CGFloat(pointCount - 1), Constants.minimumHapticSpacing)
            step = Int(clamp(x, min: 0, max: width) / spacing)
        }
    }
}

// MARK: - Lines

private struct ProbabilityLines: View, Equatable {
    struct Line: Identifiable, Equatable {
        let id: String
        let color: PolymarketProbabilityChart.SeriesColor
        let points: [PolymarketProbabilityChart.Point]

        init(_ series: PolymarketProbabilityChart.Series) {
            id = series.id
            color = series.color
            points = series.points
        }
    }

    let lines: [Line]
    let scale: PolymarketProbabilityChart.Scale
    let showsLatestMarker: Bool
    let opacity: Double

    private typealias Constants = PolymarketProbabilityChart.Constants

    var body: some View {
        Chart {
            ForEach(lines) { line in
                ForEach(line.points, id: \.date) { point in
                    LineMark(
                        x: .value(Constants.dateValueLabel, point.date),
                        y: .value(Constants.probabilityValueLabel, point.probability.doubleValue),
                        series: .value(Constants.seriesValueLabel, line.id)
                    )
                    .foregroundStyle(line.color.line.opacity(opacity))
                    .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }

                if showsLatestMarker, let last = line.points.last {
                    PointMark(
                        x: .value(Constants.dateValueLabel, last.date),
                        y: .value(Constants.probabilityValueLabel, last.probability.doubleValue)
                    )
                    .foregroundStyle(line.color.marker)
                    .symbolSize(Constants.markerSymbolArea)
                }
            }
        }
        .chartXScale(domain: scale.dateDomain)
        .chartYScale(domain: scale.probabilityDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
}

// MARK: - Latest marker pulse

private struct LatestMarkerPulse: View {
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    private typealias Constants = PolymarketProbabilityChart.Constants

    var body: some View {
        Circle()
            .fill(color)
            .frame(size: .init(bothDimensions: Constants.markerDiameter))
            .scaleEffect(isExpanded ? Constants.pulseScale : 1)
            .opacity(isExpanded ? 0 : Constants.pulseOpacity)
            .animation(
                .easeOut(duration: Constants.pulseDuration).repeatForever(autoreverses: false),
                value: isExpanded
            )
            .hidden(reduceMotion)
            .onAppear { isExpanded = !reduceMotion }
    }
}

// MARK: - Leading clip

private struct LeadingClip: Shape {
    let fraction: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width * fraction, height: rect.height))
    }
}

// MARK: - Dashed line

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

// MARK: - Interpolation

private extension PolymarketProbabilityChart.Series {
    func probability(at date: Date) -> Decimal? {
        points.probability(at: date)
    }
}

private extension [PolymarketProbabilityChart.Point] {
    func probability(at date: Date) -> Decimal? {
        guard let first, let last else { return nil }
        guard date >= first.date, date <= last.date else { return nil }
        guard date > first.date else { return first.probability }
        guard date < last.date else { return last.probability }
        guard let upperIndex = firstIndex(where: { $0.date >= date }), upperIndex > 0 else { return last.probability }

        let upper = self[upperIndex]
        let lower = self[upperIndex - 1]
        let span = upper.date.timeIntervalSince(lower.date)

        guard span > 0 else { return upper.probability }

        let fraction = Decimal(date.timeIntervalSince(lower.date) / span)

        return lower.probability + (upper.probability - lower.probability) * fraction
    }
}

// MARK: - Scale

extension PolymarketProbabilityChart {
    struct Scale: Equatable {
        let ticks: [Double]
        let probabilityDomain: ClosedRange<Double>
        let dateDomain: ClosedRange<Date>

        init?(series: [Series]) {
            let points = series.flatMap(\.points)
            let probabilities = points.map { $0.probability.doubleValue }
            let dates = Set(points.map(\.date))

            guard
                dates.count > 1,
                let lowest = probabilities.min(),
                let highest = probabilities.max(),
                let earliest = dates.min(),
                let latest = dates.max()
            else {
                return nil
            }

            let lowestPercent = lowest * Constants.percentPerUnit
            let highestPercent = highest * Constants.percentPerUnit
            let bounds = Self.paddedBounds(lowest: lowestPercent, highest: highestPercent)
            let step = Self.tickStep(from: bounds.lowerBound, to: bounds.upperBound)

            ticks = stride(
                from: (bounds.lowerBound / step).rounded(.up) * step,
                through: (bounds.upperBound / step).rounded(.down) * step,
                by: step
            )
            .map { $0 / Constants.percentPerUnit }

            probabilityDomain = (bounds.lowerBound / Constants.percentPerUnit) ... (bounds.upperBound / Constants.percentPerUnit)
            dateDomain = earliest ... latest
        }

        static func paddedBounds(lowest: Double, highest: Double) -> ClosedRange<Double> {
            let range = highest - lowest
            let padding = range > 0 ? range * Constants.paddingRatio : Constants.flatPadding
            var lower = lowest - padding
            var upper = highest + padding

            if upper - lower < Constants.minimumSpan {
                let missing = (Constants.minimumSpan - (upper - lower)) / 2
                lower -= missing
                upper += missing
            }

            if lower < 0 {
                upper -= lower
                lower = 0
            }

            if upper > Constants.percentPerUnit {
                lower -= upper - Constants.percentPerUnit
                upper = Constants.percentPerUnit
            }

            return Swift.max(lower, 0) ... Swift.min(upper, Constants.percentPerUnit)
        }

        static func tickStep(from lower: Double, to upper: Double) -> Double {
            let rough = (upper - lower) / Double(Constants.tickCount)

            guard rough > 0 else { return Constants.minimumTickStep }

            let power = log10(rough).rounded(.down)
            let normalizedStep = rough / pow(10, power)
            let factor: Double

            if normalizedStep >= 50.0.squareRoot() {
                factor = 10
            } else if normalizedStep >= 10.0.squareRoot() {
                factor = 5
            } else if normalizedStep >= 2.0.squareRoot() {
                factor = 2
            } else {
                factor = 1
            }

            return Swift.max(factor * pow(10, power), Constants.minimumTickStep)
        }

        func y(for value: Double, in height: CGFloat) -> CGFloat {
            let span = probabilityDomain.upperBound - probabilityDomain.lowerBound
            let fraction = span == 0 ? 0.5 : (value - probabilityDomain.lowerBound) / span

            return height * (1 - fraction)
        }

        func x(for date: Date, in width: CGFloat) -> CGFloat {
            let span = dateDomain.upperBound.timeIntervalSince(dateDomain.lowerBound)

            guard span > 0 else { return 0 }

            return width * clamp(date.timeIntervalSince(dateDomain.lowerBound) / span, min: 0, max: 1)
        }

        func date(atX x: CGFloat, in width: CGFloat) -> Date {
            guard width > 0 else { return dateDomain.lowerBound }

            let fraction = clamp(x / width, min: 0, max: 1)
            let span = dateDomain.upperBound.timeIntervalSince(dateDomain.lowerBound)

            return dateDomain.lowerBound.addingTimeInterval(span * fraction)
        }
    }
}

// MARK: - Constants

extension PolymarketProbabilityChart {
    enum Constants {
        static let palette: [SeriesColor] = [.blue, .green, .red, .yellow]

        static let legendBottomSpacing: CGFloat = 16
        static let periodPickerTopSpacing: CGFloat = 24
        static let legendItemSpacing: CGFloat = 8
        static let legendLineSpacing: CGFloat = 4
        static let updateAnimation: Animation = .easeInOut(duration: 0.6)
        static let legendMarkerSpacing: CGFloat = 2
        static let legendMarkerSize: CGFloat = 6
        static let legendMarkerSlotSize: CGFloat = 12
        static let legendTextSpacing: CGFloat = 4
        static let axisSpacing: CGFloat = 8
        static let dateLabelsTopSpacing: CGFloat = 16
        static let plotHeight: CGFloat = 124
        static let labelHeight: CGFloat = 16
        static let axisLabelMaximumTypeSize: DynamicTypeSize = .xxLarge
        static let probabilityLabelWidth: CGFloat = 28
        static let gridLineWidth: CGFloat = 1
        static let gridDash: [CGFloat] = [3, 3]
        static let lineWidth: CGFloat = 1.5
        static let markerSymbolArea: CGFloat = 28
        static let markerDiameter: CGFloat = 6
        static let pulseScale: CGFloat = 3
        static let pulseOpacity: Double = 0.5
        static let pulseDuration: TimeInterval = 1.4
        static let dimmedLineOpacity: Double = 0.3
        static let loadingOpacity: Double = 0.4
        static let scrubActivationDelay: Double = 0.1
        static let minimumHapticSpacing: CGFloat = 8
        static let percentPerUnit: Double = 100
        static let minimumTickStep: Double = 1
        static let minimumSpan: Double = 3
        static let paddingRatio: Double = 0.1
        static let flatPadding: Double = 2
        static let tickCount = 4
        static let skeletonBarHeight: CGFloat = 16
        static let skeletonLegendLines: [[CGFloat]] = [[120, 96], [136]]
        static let skeletonDateLabelWidths: [CGFloat] = [55, 56, 57]
        static let placeholderRowSpacing: CGFloat = 20
        static let placeholderTicks: [Decimal] = [0.65, 0.5, 0.35, 0.2]
        static let emptyStateSpacing: CGFloat = 4
        static let emptyStateIconSize: CGFloat = 20
        static let emptyStateHorizontalPadding: CGFloat = 12
        static let emptyStateVerticalPadding: CGFloat = 8
        static let emptyStateCornerRadius: CGFloat = 24
        static let skeletonPeriods: [SegmentedControl<String>.Item] = (0 ..< skeletonPeriodCount).map {
            SegmentedControl<String>.Item(id: "\($0)", title: skeletonPeriodTitle)
        }

        static let minimumPeriodCount = 2

        static let skeletonPeriodCount = 6
        static let skeletonPeriodTitle = "00"
        static let skeletonPlotRadius: CGFloat = 24
        static let dateValueLabel = "Date"
        static let probabilityValueLabel = "Probability"
        static let seriesValueLabel = "Outcome"
    }
}
