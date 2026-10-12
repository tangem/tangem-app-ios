//
//  OfframpAccountSuggestionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct OfframpAccountSuggestionsView: View {
    let suggestions: [OfframpAccountSuggestion]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.rowSpacing) {
                ForEach(suggestions) { suggestion in
                    row(suggestion)
                }
            }
            .padding(.top, Constants.topPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Subviews

private extension OfframpAccountSuggestionsView {
    func row(_ suggestion: OfframpAccountSuggestion) -> some View {
        SwiftUI.Button {
            onSelect(suggestion.id)
        } label: {
            HStack(spacing: Constants.contentSpacing) {
                title(suggestion)
                    .lineLimit(1)

                DesignSystem.Icons.ChevronRight.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
            .padding(Constants.rowPadding)
            .background(DesignSystem.Color.bgSecondary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    func title(_ suggestion: OfframpAccountSuggestion) -> some View {
        let text = Text(suggestion.matchedPrefix)
            .foregroundColor(DesignSystem.Color.textBrand)
            + Text(suggestion.accountNumberSuffix)
            .foregroundColor(DesignSystem.Color.textPrimary)
            + Text(Constants.separator)
            .foregroundColor(DesignSystem.Color.textSecondary)
            + Text(suggestion.name)
            .foregroundColor(DesignSystem.Color.textSecondary)

        return text.style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}

// MARK: - Constants

private extension OfframpAccountSuggestionsView {
    enum Constants {
        static let separator = " · "
        static let rowSpacing: CGFloat = 4
        static let rowPadding: CGFloat = 14
        static let topPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    OfframpAccountSuggestionsView(
        suggestions: [
            OfframpAccountSuggestion(
                id: "hanako",
                matchedPrefix: "082",
                accountNumberSuffix: "5200008214",
                name: "Hanako A."
            ),
            OfframpAccountSuggestion(
                id: "saburo",
                matchedPrefix: "082",
                accountNumberSuffix: "5200008215",
                name: "Saburo A."
            ),
            OfframpAccountSuggestion(
                id: "panam",
                matchedPrefix: "082",
                accountNumberSuffix: "5200008216",
                name: "Panam P."
            ),
        ],
        onSelect: { _ in }
    )
    .padding(.horizontal, 24)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
