//
//  SeedPhraseSuggestionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SeedPhraseSuggestionsView: View {
    let suggestions: [String]
    let suggestionTapped: (Int) -> Void

    @ViewBuilder
    private func suggestionBubble(with text: String, index: Int) -> some View {
        Button {
            suggestionTapped(index)
        } label: {
            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Colors.Icon.primary1)
                .cornerRadiusContinuous(10)
                .padding(.all, 4)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0 ..< suggestions.count, id: \.self) { index in
                    suggestionBubble(with: suggestions[index], index: index)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 30)
    }
}

struct SeedPhraseSuggestionsView_Preview: PreviewProvider {
    static var previews: some View {
        SeedPhraseSuggestionsView(
            suggestions: [
                "tree", "banana", "tangem", "index", "wallet", "caret", "collection", "engine",
            ],
            suggestionTapped: { _ in }
        )
    }
}
