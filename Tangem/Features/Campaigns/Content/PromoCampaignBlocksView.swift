//
//  PromoCampaignBlocksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PromoCampaignBlocksView: View {
    let blocks: [PromoCampaignContent.Block]

    var body: some View {
        VStack(spacing: Constants.blockSpacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: PromoCampaignContent.Block) -> some View {
        switch block {
        case .text(let text):
            PromoCampaignTextBlockView(text: text)
        case .highlight(let title, let text):
            PromoCampaignHighlightBlockView(title: title, text: text)
        case .items(let title, let items):
            PromoCampaignItemsBlockView(title: title, items: items)
        case .table(let table):
            PromoCampaignTableBlockView(table: table)
        }
    }
}

// MARK: - Block title

struct PromoCampaignBlockTitleView: View {
    let title: String

    var body: some View {
        Text(title)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Text

private struct PromoCampaignTextBlockView: View {
    let text: String

    var body: some View {
        Text(text)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

// MARK: - Highlight

private struct PromoCampaignHighlightBlockView: View {
    let title: String?
    let text: String

    var body: some View {
        banner
            .variant(.info)
            .glowRing(.info)
            .padding(.horizontal, 16)
    }

    private var banner: MessageBanner<EmptyView, EmptyView, EmptyView> {
        if let title {
            MessageBanner(title: title, description: text)
        } else {
            MessageBanner(title: text)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let blockSpacing: CGFloat = 24
}

// MARK: - Previews

#Preview {
    ScrollView {
        PromoCampaignBlocksView(blocks: [
            .text("Stake from 100 USDT and get cashback on every swap until the end of July."),
            .items(title: "Cashback and amounts", items: [
                .init(label: "From $10K", value: "0.10%"),
                .init(label: "From $20K", value: "0.20%"),
                .init(label: "Weekly bonus", value: "USDT\u{00A0}5"),
            ]),
            .table(.init(
                title: "Max payout and limits",
                headers: ["Option", "Amount"],
                rows: [["Per swap", "$500"], ["Per wallet per swap", "$10K"]]
            )),
            .highlight(title: "You have $30 in rewards", text: "This total includes rewards from all incentivised tokens"),
            .highlight(title: nil, text: "Until August 31"),
        ])
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    .background(DesignSystem.Color.bgPrimary)
}
