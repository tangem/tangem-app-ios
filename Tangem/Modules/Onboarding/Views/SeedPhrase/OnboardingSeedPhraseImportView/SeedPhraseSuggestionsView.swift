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
    let tappedSuggestion: (Int) -> Void
    
    @ViewBuilder
    private func bubble(with text: String, index: Int) -> some View {
        Button {
            tappedSuggestion(index)
        } label: {
            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Colors.Icon.primary1)
                .cornerRadiusContinuous(10)
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0 ..< suggestions.count, id: \.self) { index in
                    bubble(with: suggestions[index], index: index)
                }
            }
        }
        .frame(minHeight: 30)
    }
}

struct SeedPhraseSuggestionsView_Preview: PreviewProvider {
    
    static var previews: some View {
        SeedPhraseSuggestionsView(
            suggestions: [
                "tree", "banana", "tangem", "index", "wallet", "caret", "collection", "engine"
            ],
            tappedSuggestion: { _ in }
        )
    }
}
