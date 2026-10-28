//
//  PolymarketPositionPriceRangeView.swift
//  TangemPolymarketUI
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

public struct PolymarketPositionPriceRangeView: View {
    private let model: Model

    @State private var trackWidth: CGFloat = 0

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            header

            VStack(spacing: Constants.bodySpacing) {
                scale

                track

                markers
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.change.accessibilityLabel)
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var header: some View {
        SwiftUI.Button(action: model.onHintTap) {
            HStack(spacing: Constants.captionSpacing) {
                Text(Localization.predictionPositionsPriceChanges)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
            }
        }
        .buttonStyle(.plain)
    }

    private var scale: some View {
        HStack(spacing: Constants.captionSpacing) {
            Text(model.minText)

            Spacer(minLength: 0)

            Text(model.maxText)
        }
        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        .lineLimit(1)
    }

    private var track: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(DesignSystem.Color.bgTransparentPrimary)
                .frame(height: Constants.trackHeight)

            if let segment = model.change.segment {
                Capsule()
                    .fill(segment.color)
                    .frame(width: max(x(segment.upper) - x(segment.lower), 0), height: Constants.trackHeight)
                    .padding(.leading, x(segment.lower))
            }

            ForEach(model.change.dots.indexed(), id: \.0) { _, position in
                Circle()
                    .fill(DesignSystem.Color.paletteBaseWhite)
                    .frame(size: CGSize(bothDimensions: Constants.dotSide))
                    .shadow(color: DesignSystem.Color.paletteOpaqueBaseBlack25, radius: Constants.dotShadowRadius)
                    .padding(.leading, x(position) - Constants.dotSide / 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Constants.trackAreaHeight, alignment: .leading)
        .readGeometry(\.size.width, bindTo: $trackWidth)
    }

    @ViewBuilder
    private var markers: some View {
        let bought = model.change.bought
        let now = model.change.now

        switch model.change.direction {
        case .flat:
            MarkLabelsLayout(placement: .centered(now.position), markerSide: Constants.dotSide, spacing: Constants.labelSpacing) {
                label(
                    title: "\(Localization.predictionHistoryBought)\(Constants.markSeparator)\(Localization.commonNow)",
                    value: now.valueText,
                    valueColor: DesignSystem.Color.textPrimary,
                    alignment: .center
                )
            }
        case .up:
            pair(
                leading: MarkLabel(title: Localization.predictionHistoryBought, mark: bought, valueColor: DesignSystem.Color.textPrimary),
                trailing: MarkLabel(title: Localization.commonNow, mark: now, valueColor: DesignSystem.Color.textBrand)
            )
        case .down:
            pair(
                leading: MarkLabel(title: Localization.commonNow, mark: now, valueColor: DesignSystem.Color.textStatusError),
                trailing: MarkLabel(title: Localization.predictionHistoryBought, mark: bought, valueColor: DesignSystem.Color.textPrimary)
            )
        }
    }

    private func pair(leading: MarkLabel, trailing: MarkLabel) -> some View {
        MarkLabelsLayout(
            placement: .pair(leading: leading.mark.position, trailing: trailing.mark.position),
            markerSide: Constants.dotSide,
            spacing: Constants.labelSpacing
        ) {
            label(title: leading.title, value: leading.mark.valueText, valueColor: leading.valueColor, alignment: .trailing)

            label(title: trailing.title, value: trailing.mark.valueText, valueColor: trailing.valueColor, alignment: .leading)
        }
    }

    private func label(title: String, value: String, valueColor: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            Text(value)
                .style(DesignSystem.Font.captionMediumToken, color: valueColor)
        }
        .lineLimit(1)
        .fixedSize()
    }

    private func x(_ position: Double) -> CGFloat {
        MarkLabelsLayout.markerX(position, width: trackWidth, markerSide: Constants.dotSide)
    }
}

// MARK: - Model

public extension PolymarketPositionPriceRangeView {
    struct Model {
        public let minText: String
        public let maxText: String
        public let change: Change
        public let onHintTap: () -> Void

        public init(minText: String, maxText: String, change: Change, onHintTap: @escaping () -> Void) {
            self.minText = minText
            self.maxText = maxText
            self.change = change
            self.onHintTap = onHintTap
        }
    }

    struct Change {
        public let bought: Mark
        public let now: Mark

        public init(bought: Mark, now: Mark) {
            self.bought = bought
            self.now = now
        }
    }

    struct Mark {
        public let position: Double
        public let valueText: String

        public init(position: Double, valueText: String) {
            self.position = position
            self.valueText = valueText
        }
    }
}

// MARK: - Drawing

private extension PolymarketPositionPriceRangeView {
    struct MarkLabel {
        let title: String
        let mark: Mark
        let valueColor: Color
    }

    enum Direction {
        case flat
        case up
        case down
    }

    struct Segment {
        let lower: Double
        let upper: Double
        let color: Color
    }
}

private extension PolymarketPositionPriceRangeView.Change {
    var direction: PolymarketPositionPriceRangeView.Direction {
        if now.position > bought.position {
            .up
        } else if now.position < bought.position {
            .down
        } else {
            .flat
        }
    }

    var segment: PolymarketPositionPriceRangeView.Segment? {
        switch direction {
        case .flat:
            nil
        case .up:
            .init(lower: bought.position, upper: now.position, color: DesignSystem.Color.bgBrand)
        case .down:
            .init(lower: now.position, upper: bought.position, color: DesignSystem.Color.bgAccentRed)
        }
    }

    var dots: [Double] {
        switch direction {
        case .flat:
            [now.position]
        case .up, .down:
            [bought.position, now.position]
        }
    }

    var accessibilityLabel: String {
        switch direction {
        case .flat:
            "\(Localization.predictionHistoryBought), \(Localization.commonNow): \(now.valueText)"
        case .up, .down:
            "\(Localization.predictionHistoryBought): \(bought.valueText), \(Localization.commonNow): \(now.valueText)"
        }
    }
}

// MARK: - Mark labels layout

private extension PolymarketPositionPriceRangeView {
    struct MarkLabelsLayout: Layout {
        enum Placement {
            case centered(Double)
            case pair(leading: Double, trailing: Double)
        }

        let placement: Placement
        let markerSide: CGFloat
        let spacing: CGFloat

        static func markerX(_ position: Double, width: CGFloat, markerSide: CGFloat) -> CGFloat {
            let radius = markerSide / 2

            guard width > markerSide else { return radius }

            return clamp(width * CGFloat(position), min: radius, max: width - radius)
        }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let naturalWidth = sizes.reduce(0) { $0 + $1.width } + spacing * CGFloat(max(sizes.count - 1, 0))
            let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? naturalWidth
            let height = frames(width: width, sizes: sizes).map(\.maxY).max() ?? 0

            return CGSize(width: width, height: height)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let frames = frames(width: bounds.width, sizes: sizes)

            for (subview, frame) in zip(subviews, frames) {
                subview.place(
                    at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                    proposal: ProposedViewSize(frame.size)
                )
            }
        }

        private func frames(width: CGFloat, sizes: [CGSize]) -> [CGRect] {
            switch placement {
            case .centered(let position):
                guard let size = sizes.first else { return [] }

                let minX = clampedMinX(Self.markerX(position, width: width, markerSide: markerSide) - size.width / 2, width: size.width, in: width)

                return [CGRect(origin: CGPoint(x: minX, y: 0), size: size)]
            case .pair(let leadingPosition, let trailingPosition):
                guard sizes.count == 2 else { return [] }

                let leading = sizes[0]
                let trailing = sizes[1]
                let leadingX = Self.markerX(leadingPosition, width: width, markerSide: markerSide)
                let trailingX = Self.markerX(trailingPosition, width: width, markerSide: markerSide)

                guard leading.width + spacing + trailing.width <= width else {
                    return [
                        CGRect(origin: CGPoint(x: clampedMinX(leadingX - leading.width, width: leading.width, in: width), y: 0), size: leading),
                        CGRect(
                            origin: CGPoint(x: clampedMinX(trailingX, width: trailing.width, in: width), y: leading.height + spacing),
                            size: trailing
                        ),
                    ]
                }

                let leadingMinX = clamp(leadingX - leading.width, min: 0, max: width - trailing.width - spacing - leading.width)
                let trailingMinX = clamp(trailingX, min: leadingMinX + leading.width + spacing, max: width - trailing.width)

                return [
                    CGRect(origin: CGPoint(x: leadingMinX, y: 0), size: leading),
                    CGRect(origin: CGPoint(x: trailingMinX, y: 0), size: trailing),
                ]
            }
        }

        private func clampedMinX(_ minX: CGFloat, width: CGFloat, in containerWidth: CGFloat) -> CGFloat {
            clamp(minX, min: 0, max: max(containerWidth - width, 0))
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionPriceRangeView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let bodySpacing: CGFloat = 4
        static let captionSpacing: CGFloat = 4
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let trackHeight: CGFloat = 6
        static let trackAreaHeight: CGFloat = 16
        static let dotSide: CGFloat = 10
        static let dotShadowRadius: CGFloat = 2
        static let labelSpacing: CGFloat = 4
        static let markSeparator = " \u{00B7} "
    }
}
