//
//  FeedSearchRecentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct FeedSearchRecentView: View {
    let history: FeedSearchHistory
    let onSelectToken: (FeedRecentToken) -> Void
    let onSelectQuery: (FeedRecentQuery) -> Void
    let onRemoveQuery: (FeedRecentQuery) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            FeedSearchSectionHeader(title: Constants.title, actionTitle: Constants.clearTitle, action: onClear)
                .padding(.horizontal, Constants.horizontalPadding)

            if history.tokens.isNotEmpty {
                tokensRow
            }

            if history.queries.isNotEmpty {
                queriesList
            }
        }
    }
}

// MARK: - Subviews

private extension FeedSearchRecentView {
    var tokensRow: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Constants.tokenSpacing) {
                ForEach(history.tokens) { token in
                    FeedSearchRecentTokenView(token: token) {
                        onSelectToken(token)
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .scrollIndicators(.hidden)
    }

    var queriesList: some View {
        VStack(spacing: 0) {
            ForEach(history.queries) { query in
                queryRow(query)
            }
        }
    }

    func queryRow(_ query: FeedRecentQuery) -> some View {
        Row(title: query.value)
            .start(icon: DesignSystem.Icons.Clock.regular24)
            .end { removeButton(for: query) }
            .showDivider(query.id != history.queries.last?.id)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectQuery(query)
            }
    }

    func removeButton(for query: FeedRecentQuery) -> some View {
        TangemUI.Button(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Constants.removeAccessibilityLabel) {
            onRemoveQuery(query)
        }
        .styleType(.ghost)
        .size(.x9)
        .padding(-Constants.removeButtonInset)
    }
}

// MARK: - Constants

private extension FeedSearchRecentView {
    enum Constants {
        static let sectionSpacing: CGFloat = 12
        static let tokenSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let removeButtonInset: CGFloat = 6
        static let title = Localization.feedSearchRecentTitle
        static let clearTitle = Localization.feedSearchRecentClear
        static let removeAccessibilityLabel = "Remove"
    }
}
