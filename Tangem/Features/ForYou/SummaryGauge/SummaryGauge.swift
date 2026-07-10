//
//  SummaryGauge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct SummaryGaugeView: View {
    let assets: [SummaryGaugeAsset]

    @State private var selectedID: GaugeSegment.ID?

    private let balanceFormatter = BalanceFormatter()

    private var segments: [GaugeSegment] { SummaryGaugeChart.segments(for: assets) }
    private var hasData: Bool { !segments.isEmpty }
    private var totalValue: Decimal { assets.reduce(0) { $0 + $1.fiatValue } }
    private var totalValueDouble: Double { NSDecimalNumber(decimal: totalValue).doubleValue }
    private var safeTotalValue: Double { max(totalValueDouble, .leastNonzeroMagnitude) }
    private var selectedSegment: GaugeSegment? { segments.first { $0.id == selectedID } }

    var body: some View {
        RingGauge(
            segments: segments,
            total: totalValueDouble,
            selectedID: selectedSegment?.id,
            onSelect: { id in selectedID = (selectedID == id) ? nil : id }
        )
        .overlay { centerContent }
        .overlay { tooltip }
    }

    @ViewBuilder
    private var centerContent: some View {
        if hasData {
            VStack(spacing: 2) {
                Text(balanceFormatter.formatFiatBalance(totalValue))
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(Localization.marketChartBubbleTotalValue)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        } else {
            Text(Localization.marketChartBubbleNoData)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        }
    }

    @ViewBuilder
    private var tooltip: some View {
        if let segment = selectedSegment {
            GaugeTooltip(
                title: segment.name,
                value: balanceFormatter.formatFiatBalance(fiatValue(for: segment)),
                percent: Self.percentText(segment.value / safeTotalValue)
            )
            .position(tooltipAnchor(for: segment))
            .transition(.opacity)
        }
    }

    private func tooltipAnchor(for segment: GaugeSegment) -> CGPoint {
        let radius = (RingGauge.diameter - RingGauge.defaultLineWidth) / 2
        let center = CGPoint(x: RingGauge.diameter / 2, y: RingGauge.diameter / 2)

        var cursor = 0.0
        var midpoint = 0.0
        for candidate in segments {
            let fraction = candidate.value / safeTotalValue
            if candidate.id == segment.id {
                midpoint = cursor + fraction / 2
                break
            }
            cursor += fraction
        }

        // Fraction 0 is 12 o'clock, increasing clockwise — matching how the ring is drawn.
        let angle = CGFloat(midpoint) * 2 * .pi
        return CGPoint(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
    }

    private func fiatValue(for segment: GaugeSegment) -> Decimal {
        assets.first { $0.id == segment.id }?.fiatValue ?? 0
    }

    /// NumberFormatter init is expensive; reuse a single instance across body evaluations.
    /// Safe as shared mutable state because SwiftUI evaluates `body` on the main thread.
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func percentText(_ share: Double) -> String {
        let percent = percentFormatter.string(from: (share * 100) as NSNumber) ?? "0"
        return "\(percent)%"
    }
}

// MARK: - Previews

#Preview {
    func asset(_ name: String, _ value: Decimal) -> SummaryGaugeAsset {
        SummaryGaugeAsset(id: UUID(), name: name, fiatValue: value)
    }

    let portfolios: [[SummaryGaugeAsset]] = [
        [asset("Ethereum", 5750), asset("Solana", 1800), asset("Bitcoin", 1300), asset("Polygon", 1150), asset("Avalanche", 1450), asset("Cardano", 1900)],
        [asset("Ethereum", 5750), asset("Solana", 1800), asset("Bitcoin", 1300), asset("Polygon", 1150)],
        [asset("Ethereum", 5200), asset("Solana", 3800), asset("Bitcoin", 1000)],
        [asset("Ethereum", 5800), asset("Solana", 4200)],
        [asset("Ethereum", 10000)],
    ]

    return ScrollView {
        VStack(spacing: 24) {
            ForEach(Array(portfolios.enumerated()), id: \.offset) { _, assets in
                SummaryGaugeView(assets: assets)
            }

            SummaryGaugeView(assets: [])
        }
        .padding(24)
    }
    .background(DesignSystem.Color.bgTertiary)
}
