//
//  TransactionDetailsInfoSectionView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct TransactionDetailsInfoSectionViewData: Equatable {
    let rows: [Row]

    struct Row: Equatable {
        let title: String
        let content: Content

        enum Content: Equatable {
            /// Rate / Network fee
            case text(String)
            /// Provider / Validator
            case link(Link)
        }

        struct Link: Equatable {
            let text: String
            let iconURL: URL?
            /// `nil` → the row is non-interactive (no trailing arrow, no tap).
            @IgnoredEquatable var handler: (() -> Void)?
        }
    }
}

struct TransactionDetailsInfoSectionView: View {
    let data: TransactionDetailsInfoSectionViewData

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(Array(data.rows.enumerated()), id: \.offset) { index, row in
                rowView(row, showsDivider: index != data.rows.count - 1)
            }
        }
        .background(
            DesignSystem.Color.bgTertiary,
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    @ViewBuilder
    private func rowView(_ row: TransactionDetailsInfoSectionViewData.Row, showsDivider: Bool) -> some View {
        switch row.content {
        case .text(let value):
            // Native `value` slot: it gets the row's trailing-preserved width priority, so long values
            // (e.g. the rate) fit where a custom accessory would get truncated.
            TangemRow(title: row.title, value: value)
                .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                .contentLead(.end)
                .valueLineLimit(1)
                .showDivider(showsDivider)
        case .link(let link):
            let row = TangemRow(title: row.title)
                .valueAccessory { linkValue(link) }
                .showDivider(showsDivider)

            if let handler = link.handler {
                row.onTap(handler)
            } else {
                row
            }
        }
    }

    private func linkValue(_ link: TransactionDetailsInfoSectionViewData.Row.Link) -> some View {
        HStack(spacing: 4) {
            if let iconURL = link.iconURL {
                IconView(url: iconURL, size: CGSize(bothDimensions: 20))
            }

            Text(link.text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            // The trailing "open external" arrow only makes sense when the row is actually tappable.
            if link.handler != nil {
                // [REDACTED_TODO_COMMENT]
                Assets.arrowRightUpMini.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(size: CGSize(bothDimensions: 16))
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Info section") {
    TransactionDetailsInfoSectionView(data: .init(rows: [
        .init(title: "Provider", content: .link(.init(text: "DEX • Mercuryo", iconURL: nil, handler: {}))),
        .init(title: "Rate", content: .text("1 POL ≈ 0.36 USDT")),
        .init(title: "Network fee", content: .text("0.00056 ETH")),
    ]))
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
#endif // DEBUG
