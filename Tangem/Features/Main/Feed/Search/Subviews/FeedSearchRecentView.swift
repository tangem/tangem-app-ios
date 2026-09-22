//
//  FeedSearchRecentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct FeedSearchRecentView: View {
    let queries: [FeedRecentQuery]
    let onSelectQuery: (FeedRecentQuery) -> Void
    let onRemoveQuery: (FeedRecentQuery) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            FeedSearchSectionHeader(title: Constants.title)
                .padding(.horizontal, Constants.horizontalPadding)

            queriesList
        }
    }
}

// MARK: - Subviews

private extension FeedSearchRecentView {
    var queriesList: some View {
        VStack(spacing: 0) {
            ForEach(queries) { query in
                queryRow(query)
            }
        }
    }

    func queryRow(_ query: FeedRecentQuery) -> some View {
        Row(title: query.value)
            .start(icon: DesignSystem.Icons.Clock.regular24)
            .end { removeButton(for: query) }
            .showDivider(query.id != queries.last?.id)
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
        static let horizontalPadding: CGFloat = 16
        static let removeButtonInset: CGFloat = 6
        static let title = Localization.marketsSearchHintHeader
        static let removeAccessibilityLabel = "Remove"
    }
}
