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

    struct Row: Identifiable, Equatable {
        let id: String
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
            @IgnoredEquatable var handler: () -> Void
        }
    }
}

struct TransactionDetailsInfoSectionView: View {
    let data: TransactionDetailsInfoSectionViewData

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(Array(data.rows.enumerated()), id: \.element.id) { index, row in
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
            TangemRow(title: row.title, value: value)
                .showDivider(showsDivider)
        case .link(let link):
            TangemRow(title: row.title)
                .valueAccessory { linkValue(link) }
                .onTap(link.handler)
                .showDivider(showsDivider)
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

// MARK: - Previews

#if DEBUG
#Preview("Info section") {
    TransactionDetailsInfoSectionView(data: .init(rows: [
        .init(id: "provider", title: "Provider", content: .link(.init(text: "DEX • Mercuryo", iconURL: nil, handler: {}))),
        .init(id: "rate", title: "Rate", content: .text("1 POL ≈ 0.36 USDT")),
        .init(id: "fee", title: "Network fee", content: .text("0.00056 ETH")),
    ]))
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
#endif // DEBUG
