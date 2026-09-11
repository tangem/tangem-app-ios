//
//  TangemPayCashbackChartView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemFoundation

struct TangemPayCashbackChartView: View {
    let formattedTotal: String
    let items: [Item]
    let isZeroTotal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title

            VStack(spacing: 8) {
                bars

                monthsAxis
            }
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Subviews

private extension TangemPayCashbackChartView {
    var title: some View {
        SensitiveText(
            builder: { Localization.tangempayCashbackTotalEarned($0) },
            sensitive: formattedTotal
        )
        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
        .padding(.vertical, 16)
    }

    var bars: some View {
        HStack(alignment: .bottom, spacing: Constants.columnSpacing) {
            ForEach(items) { item in
                VStack(spacing: Constants.barSpacing) {
                    if showsValueLabel(for: item) {
                        SensitiveText(item.formattedValue)
                            .style(DesignSystem.Font.captionMediumToken, color: color(for: item))
                            .lineLimit(1)
                    }

                    bar(for: item)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Constants.maxBarHeight, alignment: .bottom)
    }

    func bar(for item: Item) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: Constants.barCornerRadius,
            topTrailingRadius: Constants.barCornerRadius
        )
        .fill(barColor(for: item))
        .frame(height: barHeight(for: item))
        .accessibilityHidden(true)
    }

    var monthsAxis: some View {
        HStack(spacing: Constants.columnSpacing) {
            ForEach(items) { item in
                Text(item.month)
                    .style(DesignSystem.Font.captionMediumToken, color: color(for: item))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Layout

private extension TangemPayCashbackChartView {
    func barHeight(for item: Item) -> CGFloat {
        guard !isZeroTotal, item.value > 0, let maxValue = items.map(\.value).max(), maxValue > 0 else {
            return Constants.minBarHeight
        }

        let ratio = CGFloat((item.value / maxValue).doubleValue)

        return min(max(Constants.maxBarHeight * ratio, Constants.minBarHeight), Constants.maxBarHeight)
    }

    func showsValueLabel(for item: Item) -> Bool {
        item.value != 0 || item.id == items.last?.id
    }

    func barColor(for item: Item) -> some ShapeStyle {
        let innerShadow: ShadowStyle = .inner(color: Color(hex: "#FFEFEF").opacity(0.25), radius: 12, y: 6)

        if !isZeroTotal, item.value < 0 {
            return AnyShapeStyle(DesignSystem.Color.bgStatusError.shadow(innerShadow))
        }

        return item.isSelected
            ? AnyShapeStyle(DesignSystem.Color.bgBrand.shadow(innerShadow))
            : AnyShapeStyle(DesignSystem.Color.bgTertiary)
    }

    func color(for item: Item) -> Color {
        item.isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textTertiary
    }

    enum Constants {
        static let columnSpacing: CGFloat = 16
        static let barSpacing: CGFloat = 8
        static let barCornerRadius: CGFloat = 8
        static let maxBarHeight: CGFloat = 136
        static let minBarHeight: CGFloat = 2
    }
}

// MARK: - Item

extension TangemPayCashbackChartView {
    struct Item: Identifiable {
        let month: String
        let value: Decimal
        let formattedValue: String
        let isSelected: Bool

        var id: String { month }
    }
}

// MARK: - Previews

#Preview {
    TangemPayCashbackChartView(
        formattedTotal: "$132.15",
        items: [
            .init(month: "Feb", value: 12.02, formattedValue: "$67.02", isSelected: false),
            .init(month: "Mar", value: 44.22, formattedValue: "$765.22", isSelected: false),
            .init(month: "Apr", value: 38.52, formattedValue: "$567.52", isSelected: false),
            .init(month: "May", value: 26.10, formattedValue: "$670.10", isSelected: false),
            .init(month: "Jun", value: 32.15, formattedValue: "$0.15", isSelected: true),
        ],
        isZeroTotal: false
    )
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Refunded month") {
    TangemPayCashbackChartView(
        formattedTotal: "$117.66",
        items: [
            .init(month: "Feb", value: 12.02, formattedValue: "$12.02", isSelected: false),
            .init(month: "Mar", value: 44.22, formattedValue: "$44.22", isSelected: false),
            .init(month: "Apr", value: 38.52, formattedValue: "$38.52", isSelected: false),
            .init(month: "May", value: 26.10, formattedValue: "$26.10", isSelected: false),
            .init(month: "Jun", value: -3.20, formattedValue: "-$3.20", isSelected: true),
        ],
        isZeroTotal: false
    )
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Zero total") {
    TangemPayCashbackChartView(
        formattedTotal: "$0.00",
        items: [
            .init(month: "Feb", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Mar", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Apr", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "May", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Jun", value: 0, formattedValue: "$0.00", isSelected: true),
        ],
        isZeroTotal: true
    )
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
