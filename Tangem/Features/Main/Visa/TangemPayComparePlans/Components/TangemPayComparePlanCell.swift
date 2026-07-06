//
//  TangemPayComparePlanCell.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayComparePlanCell: View {
    let cell: TangemPayComparePlansSheetViewModel.Cell

    var body: some View {
        content
            .padding(16)
            .frame(width: Constants.width, height: Constants.height, alignment: .topLeading)
            .background(DesignSystem.Color.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch cell {
        case .availableCards(let cardType, let cardCount):
            availableCardsContent(cardType: cardType, cardCount: cardCount)
        case .value(let primary, let caption):
            valueContent(primary: primary, caption: caption)
        }
    }

    private func availableCardsContent(cardType: String, cardCount: String) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                Text(cardType)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Spacer(minLength: 0)

                cardCountText(cardCount)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // [REDACTED_TODO_COMMENT]
            TangemPaySmallCardViewRedesigned(state: .issued(cardNumberEnd: "0000"))
        }
    }

    private func valueContent(primary: String, caption: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(primary)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            if let caption {
                Spacer(minLength: 0)

                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func cardCountText(_ cardCount: String) -> some View {
        // [REDACTED_TODO_COMMENT]
        let count = Text(cardCount).foregroundColor(DesignSystem.Color.textPrimary)
        let suffix = Text(" cards in account").foregroundColor(DesignSystem.Color.textSecondary)

        return (count + suffix)
            .font(token: DesignSystem.Font.captionMediumToken)
    }
}

private extension TangemPayComparePlanCell {
    enum Constants {
        static let width: CGFloat = 332
        static let height: CGFloat = 112
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 8) {
        TangemPayComparePlanCell(cell: .availableCards(cardType: "Virtual", cardCount: "Up to 3"))
        TangemPayComparePlanCell(cell: .value(primary: "$10,000", caption: "Per card"))
        TangemPayComparePlanCell(cell: .value(primary: "Platinum", caption: nil))
    }
    .padding()
}
#endif // DEBUG
