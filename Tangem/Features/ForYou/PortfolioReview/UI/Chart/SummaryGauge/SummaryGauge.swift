//
//  SummaryGauge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct SummaryGaugeView: View {
    let assets: [SummaryGaugeAsset]
    /// Non-nil forces the no-data center bubble (empty ring); nil renders the loaded total.
    var noDataText: String? = nil
    /// Owned by the card so a tap anywhere off the ring can clear the selection.
    @Binding var selectedID: GaugeSegment.ID?
    var onSegmentTap: (() -> Void)? = nil

    @State private var pillSize: CGSize = .zero

    private let balanceFormatter = BalanceFormatter()
    private let shareFormatter = PortfolioShareFormatter()

    private var segments: [GaugeSegment] { SummaryGaugeChart.segments(for: assets) }
    private var totalValue: Decimal { assets.reduce(0) { $0 + $1.fiatValue } }
    private var totalValueDouble: Double { totalValue.doubleValue }
    private var safeTotalValue: Double { max(totalValueDouble, .leastNonzeroMagnitude) }
    private var selectedSegment: GaugeSegment? { segments.first { $0.id == selectedID } }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                gauge(cardSize: proxy.size)
                tooltipOverlay(cardSize: proxy.size)
            }
        }
        .frame(height: Constants.blockHeight)
        .frame(maxWidth: .infinity)
    }

    private func gauge(cardSize: CGSize) -> some View {
        RingGauge(
            segments: segments,
            total: totalValueDouble,
            selectedID: selectedSegment?.id,
            onSelect: { id in
                withAnimation(Constants.tooltipEnterSpring) { selectedID = id }
            },
            onSegmentTap: onSegmentTap
        )
        .overlay { centerContent }
        .position(x: cardSize.width / 2, y: Constants.ringTopPadding + RingGauge.Constants.diameter / 2)
    }

    @ViewBuilder
    private var centerContent: some View {
        if let noDataText {
            Text(noDataText)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 36)
        } else {
            VStack(spacing: 2) {
                SensitiveText(balanceFormatter.formatFiatBalance(totalValue))
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(Localization.marketChartBubbleTotalValue)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 36)
        }
    }

    @ViewBuilder
    private func tooltipOverlay(cardSize: CGSize) -> some View {
        if let segment = selectedSegment, let position = tooltipPosition(for: segment, cardSize: cardSize) {
            GaugeTooltip(
                title: segment.name,
                value: balanceFormatter.formatFiatBalance(fiatValue(for: segment)),
                percent: percentText(for: segment)
            )
            .fixedSize()
            .readGeometry(\.size, bindTo: $pillSize)
            .position(position)
            .allowsHitTesting(false) // taps pass through to the ring so slices stay switchable
            .transition(Constants.tooltipTransition)
        }
    }

    private func tooltipPosition(for segment: GaugeSegment, cardSize: CGSize) -> CGPoint? {
        guard let index = segments.firstIndex(where: { $0.id == segment.id }) else { return nil }

        // Must use the same sweeps and the same cap overlap the ring draws, else the anchor drifts off the
        // drawn slice end and, for a slice narrower than the cap, lands on its neighbour.
        let sweeps = GaugeSweeps.visualSweepAngles(weights: segments.map { CGFloat($0.value / safeTotalValue) })
        let capOverlapDeg = GaugeSweeps.capOverlapDeg(
            strokeWidth: RingGauge.Constants.defaultLineWidth,
            arcDiameter: RingGauge.Constants.diameter - RingGauge.Constants.defaultLineWidth
        )

        guard let anchor = SegmentTooltipPositioning.anchor(
            selectedIndex: index,
            sweepsDeg: sweeps,
            capOverlapDeg: capOverlapDeg,
            cardSize: cardSize,
            strokeWidth: RingGauge.Constants.defaultLineWidth,
            ringDiameter: RingGauge.Constants.diameter,
            ringTopPadding: Constants.ringTopPadding
        ) else {
            return nil
        }

        return SegmentTooltipPositioning.pillCenter(
            anchor: anchor,
            pillSize: pillSize,
            cardSize: cardSize,
            strokeWidth: RingGauge.Constants.defaultLineWidth
        )
    }

    private func fiatValue(for segment: GaugeSegment) -> Decimal {
        assets.first { $0.id == segment.id }?.fiatValue ?? 0
    }

    /// The slice's real share of the total (not the floored visual sweep), stated the way the row under the
    /// chart states it.
    private func percentText(for segment: GaugeSegment) -> String {
        let share = totalValue > 0 ? fiatValue(for: segment) / totalValue : 0

        return shareFormatter.string(for: share)
    }
}

// MARK: - Constants

private extension SummaryGaugeView {
    enum Constants {
        static let ringTopPadding: CGFloat = 32
        static let blockHeight: CGFloat = RingGauge.Constants.diameter + ringTopPadding * 2

        // Enter: scale-spring pop-in + fast fade. Exit: quick fade (scale stays).
        static let tooltipEnterSpring: Animation = .interpolatingSpring(mass: 1, stiffness: 1100, damping: 54.4)
        static let tooltipTransition: AnyTransition = .asymmetric(
            insertion: .scale(scale: 0.8, anchor: .center)
                .combined(with: .opacity)
                .animation(tooltipEnterSpring),
            removal: .opacity.animation(.linear(duration: 0.075))
        )
    }
}

// MARK: - Previews

#Preview {
    func asset(_ name: String, _ value: Decimal) -> SummaryGaugeAsset {
        SummaryGaugeAsset(id: name, name: name, fiatValue: value, segmentColor: nil)
    }

    // Stands in for the mapper: rank by value, then colour as far as the palette reaches.
    func ranked(_ assets: [SummaryGaugeAsset]) -> [SummaryGaugeAsset] {
        let byValue = assets.sorted { $0.fiatValue > $1.fiatValue }
        let slices = PortfolioReviewSegmentPalette.slices(forRanked: byValue.filter { $0.fiatValue > 0 }.map(\.id))

        return byValue.map {
            SummaryGaugeAsset(id: $0.id, name: $0.name, fiatValue: $0.fiatValue, segmentColor: slices[$0.id]?.arc)
        }
    }

    let portfolios: [[SummaryGaugeAsset]] = [
        [asset("Ethereum", 5750), asset("Solana", 1800), asset("Bitcoin", 1300), asset("Polygon", 1150), asset("Avalanche", 1450), asset("Cardano", 1900)],
        [asset("Ethereum", 5000), asset("Solana", 3000), asset("Bitcoin", 1000), asset("Polygon", 800), asset("Avalanche", 120), asset("Cardano", 80)],
        [asset("Ethereum", 5750), asset("Solana", 1800), asset("Bitcoin", 1300), asset("Polygon", 1150)],
        [asset("Ethereum", 5200), asset("Solana", 3800), asset("Bitcoin", 1000)],
        [asset("Ethereum", 5800), asset("Solana", 4200)],
        [asset("Ethereum", 10000)],
    ]

    return ScrollView {
        VStack(spacing: 24) {
            ForEach(Array(portfolios.enumerated()), id: \.offset) { _, assets in
                SummaryGaugeView(assets: ranked(assets), selectedID: .constant(nil))
            }

            SummaryGaugeView(assets: [], noDataText: Localization.marketChartBubbleNoData, selectedID: .constant(nil))
        }
        .padding(24)
    }
    .background(DesignSystem.Color.bgTertiary)
}
