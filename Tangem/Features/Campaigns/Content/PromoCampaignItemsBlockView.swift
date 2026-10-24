//
//  PromoCampaignItemsBlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PromoCampaignItemsBlockView: View {
    let title: String?
    let items: [PromoCampaignContent.Item]

    var body: some View {
        VStack(spacing: 0) {
            if let title {
                PromoCampaignBlockTitleView(title: title)
            }

            VStack(spacing: Constants.tileSpacing) {
                ForEach(Array(stride(from: 0, to: items.count, by: Constants.tilesPerRow)), id: \.self) { rowStart in
                    HStack(spacing: Constants.tileSpacing) {
                        ForEach(rowStart ..< min(rowStart + Constants.tilesPerRow, items.count), id: \.self) { index in
                            tile(items[index])
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func tile(_ item: PromoCampaignContent.Item) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.label)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            Text(item.value)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: Constants.tileMinHeight, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(DesignSystem.Color.bgTransparentPrimary)
        .cornerRadiusContinuous(Constants.tileCornerRadius)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private enum Constants {
    static let tilesPerRow = 2
    static let tileSpacing: CGFloat = 8
    static let tileMinHeight: CGFloat = 40
    static let tileCornerRadius: CGFloat = 24
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        PromoCampaignItemsBlockView(title: "Cashback and amounts", items: [
            .init(label: "From $10K", value: "0.10%"),
            .init(label: "From $10K", value: "0.10%"),
            .init(label: "From $20K", value: "0.20%"),
            .init(label: "From $20K", value: "0.20%"),
        ])

        PromoCampaignItemsBlockView(title: nil, items: [
            .init(label: "From $10K", value: "0.10%"),
            .init(label: "From $20K", value: "0.20%"),
            .init(label: "Weekly bonus", value: "USDT\u{00A0}5"),
        ])
    }
    .padding(.horizontal, 8)
    .background(DesignSystem.Color.bgPrimary)
}
