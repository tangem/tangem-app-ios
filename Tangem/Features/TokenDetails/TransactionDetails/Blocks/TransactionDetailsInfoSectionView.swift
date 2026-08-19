//
//  TransactionDetailsInfoSectionView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

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
            /// Optional trailing detail (e.g. the CEX/DEX provider type)
            let secondaryText: String?
            let action: TransactionDetailsViewModel.ViewAction?
        }
    }
}

struct TransactionDetailsInfoSectionView: View {
    let data: TransactionDetailsInfoSectionViewData
    let onAction: (TransactionDetailsViewModel.ViewAction) -> Void

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(Array(data.rows.enumerated()), id: \.element.id) { index, row in
                rowView(row, showsDivider: index != data.rows.count - 1)
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: TransactionDetailsInfoSectionViewData.Row, showsDivider: Bool) -> some View {
        switch row.content {
        case .text(let value):
            TangemUI.Row(title: row.title, value: value)
                .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                .contentLead(.start)
                .valueLineLimit(1)
                .showDivider(showsDivider)
        case .link(let link):
            TangemUI.Row(title: row.title)
                .valueAccessory { linkValue(link) }
                .contentLead(.end)
                .showDivider(showsDivider)
                .ifLet(link.action) { view, action in
                    view.onTap { onAction(action) }
                }
        }
    }

    private func linkValue(_ link: TransactionDetailsInfoSectionViewData.Row.Link) -> some View {
        HStack(spacing: 4) {
            Text(link.text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)

            if let secondaryText = link.secondaryText {
                Text("\(AppConstants.dotSign) \(secondaryText)")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            if link.action != nil {
                DesignSystem.Icons.ArrowTopRight.regular20.image
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

#Preview("Info section") {
    TransactionDetailsInfoSectionView(
        data: .init(rows: [
            .init(id: "provider", title: "Provider", content: .link(.init(text: "Mercuryo", secondaryText: "DEX", action: .close))),
            .init(id: "rate", title: "Rate", content: .text("1,00 POL ≈ 0,07703936 USDT")),
            .init(id: "networkFee", title: "Network fee", content: .text("0.00056 ETH")),
        ]),
        onAction: { _ in }
    )
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
