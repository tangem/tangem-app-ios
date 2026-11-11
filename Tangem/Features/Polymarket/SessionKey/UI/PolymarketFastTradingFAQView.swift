//
//  PolymarketFastTradingFAQView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PolymarketFastTradingFAQView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PolymarketFastTradingStrings.infoTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .padding(Constants.titlePadding)

            PolymarketFastTradingInfoTiles(onDurationInfo: nil)

            VStack(spacing: 0) {
                ForEach(indexed: Self.sections, id: \.1) { index, section in
                    PolymarketTextSection(title: section.title, text: section.text, isSeparated: index >= Constants.firstSeparatedSection)
                }
            }
            .padding(.horizontal, Constants.sectionHorizontalPadding)
        }
        .padding(.bottom, Constants.bottomPadding)
    }
}

// MARK: - Content

private extension PolymarketFastTradingFAQView {
    static let sections: [PolymarketFastTradingStrings.Section] = [
        PolymarketFastTradingStrings.whatItIs,
        PolymarketFastTradingStrings.howLongItLasts,
        PolymarketFastTradingStrings.whatItCanDo,
        PolymarketFastTradingStrings.whatItCantDo,
        PolymarketFastTradingStrings.youAreInControl,
    ]

    enum Constants {
        static let titlePadding: CGFloat = 24
        static let sectionHorizontalPadding: CGFloat = 24
        static let firstSeparatedSection = 2
        static let bottomPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    Color.clear.modal(
        isPresented: .constant(true),
        size: .full,
        navigation: .title(PolymarketFastTradingStrings.title),
        content: { PolymarketFastTradingFAQView() }
    )
}
