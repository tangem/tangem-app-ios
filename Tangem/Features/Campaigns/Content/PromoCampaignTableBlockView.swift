//
//  PromoCampaignTableBlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PromoCampaignTableBlockView: View {
    let table: PromoCampaignContent.Table

    var body: some View {
        VStack(spacing: 0) {
            if let title = table.title {
                PromoCampaignBlockTitleView(title: title)
            }

            if !table.headers.isEmpty {
                row(cells: table.headers, color: DesignSystem.Color.textSecondary, showsDivider: true)
            }

            ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                row(cells: cells, color: DesignSystem.Color.textPrimary, showsDivider: index < table.rows.count - 1)
            }
        }
    }

    @ViewBuilder
    private func row(cells: [String], color: Color, showsDivider: Bool) -> some View {
        let label = cells.first ?? ""
        let values = Array(cells.dropFirst())

        if values.count > 1 {
            TangemUI.Row(title: label)
                .valueAccessory { valuesView(values, color: color) }
                .overrideTextColors(RowOverrideTextColors(title: color))
                .titleLineLimit(nil)
                .contentLead(.equal)
                .showDivider(showsDivider)
        } else {
            TangemUI.Row(title: label, value: values.first)
                .overrideTextColors(RowOverrideTextColors(title: color, value: color))
                .titleLineLimit(nil)
                .valueLineLimit(nil)
                .contentLead(.end)
                .showDivider(showsDivider)
        }
    }

    private func valuesView(_ values: [String], color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .style(DesignSystem.Font.bodyMediumToken, color: color)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        PromoCampaignTableBlockView(table: .init(
            title: "Max payout and limits",
            headers: ["Option", "Amount"],
            rows: [["Per swap", "$500"], ["Per wallet per swap", "$10K"]]
        ))

        PromoCampaignTableBlockView(table: .init(
            title: nil,
            headers: [],
            rows: [["Tier", "0.10%", "1,500"], ["Gold", "0.20%", "3,000"]]
        ))
    }
    .padding(.horizontal, 8)
    .background(DesignSystem.Color.bgPrimary)
}
