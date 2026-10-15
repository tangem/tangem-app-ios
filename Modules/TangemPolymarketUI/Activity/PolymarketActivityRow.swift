//
//  PolymarketActivityRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

public struct PolymarketActivityRow: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        Row(title: model.title, subtitle: model.subtitle, value: model.amount)
            .start {
                PolymarketActivityIcon(icon: model.icon)
                    .padding(.trailing, Constants.iconSpacingCompensation)
            }
            .verticalAlignment(.center)
            .overrideTextColors(RowOverrideTextColors(title: model.tone.textColor, value: model.tone.textColor))
            .truncationModes(RowTruncationModes(subtitle: model.truncatesSubtitleInMiddle ? .middle : .tail))
    }
}

// MARK: - Constants

private extension PolymarketActivityRow {
    enum Constants {
        static let iconSpacingCompensation: CGFloat = -4
    }
}

// MARK: - Model

public extension PolymarketActivityRow {
    struct Model: Identifiable, Hashable {
        public let id: String
        public let icon: Icon
        public let title: String
        public let subtitle: String?
        public let amount: String
        public let tone: PolymarketValueTone
        public let truncatesSubtitleInMiddle: Bool

        public init(
            id: String,
            icon: Icon,
            title: String,
            subtitle: String?,
            amount: String,
            tone: PolymarketValueTone,
            truncatesSubtitleInMiddle: Bool = false
        ) {
            self.id = id
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.amount = amount
            self.tone = tone
            self.truncatesSubtitleInMiddle = truncatesSubtitleInMiddle
        }
    }

    enum Icon: Hashable {
        case market(URL?)
        case glyph(ImageType)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 0) {
        PolymarketActivityRow(model: .init(
            id: "1",
            icon: .glyph(DesignSystem.Icons.ArrowUp.regular20),
            title: "Withdrawn",
            subtitle: nil,
            amount: "- $5,000.00",
            tone: .neutral
        ))

        PolymarketActivityRow(model: .init(
            id: "2",
            icon: .market(nil),
            title: "Redeemed",
            subtitle: "Because had won in “Will Trump strike the Moon from North Korea”",
            amount: "+ $350.31",
            tone: .positive
        ))
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
