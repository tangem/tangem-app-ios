//
//  MarketsPortfolioPlateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsPortfolioPlateView<Trailing: View>: View {
    let iconURL: URL
    let title: AttributedString
    var titleColor: Color = .Tangem.Text.Neutral.tertiary
    @ViewBuilder let trailing: Trailing

    @ScaledMetric private var iconSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            IconView(
                url: iconURL,
                size: CGSize(bothDimensions: iconSize),
                forceKingfisher: true
            )

            Text(title)
                .style(Font.Tangem.Caption12.medium, color: titleColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .background(
            Capsule()
                .fill(Color.Tangem.Surface.level3)
        )
    }
}

enum MarketsPortfolioPlateTitle {
    static func make(_ raw: String, emphasizedColor: Color) -> AttributedString {
        guard var attributed = try? AttributedString(markdown: raw) else {
            return AttributedString(raw)
        }

        for run in attributed.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            attributed[run.range].foregroundColor = emphasizedColor
        }

        return attributed
    }
}
