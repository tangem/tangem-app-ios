//
//  SeedPhraseSuggestionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SeedPhraseSuggestionsView: View {
    let suggestions: [String]
    let suggestionTapped: (Int) -> Void

    @ViewBuilder
    private func suggestionBubble(with text: String, index: Int) -> some View {
        Button {
            suggestionTapped(index)
        } label: {
            Text(text)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textInversePrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(DesignSystem.Color.bgInverse)
                .cornerRadiusContinuous(10)
                .padding(.all, 4)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(indexed: suggestions, id: \.0) { index, suggestion in
                    suggestionBubble(with: suggestion, index: index)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 30)
    }
}

#Preview {
    SeedPhraseSuggestionsView(
        suggestions: [
            "tree", "banana", "tangem", "index", "wallet", "caret", "collection", "engine",
        ],
        suggestionTapped: { _ in }
    )
}
