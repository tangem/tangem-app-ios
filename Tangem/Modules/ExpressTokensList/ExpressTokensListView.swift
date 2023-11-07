//
//  ExpressTokensListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressTokensListView: View {
    @ObservedObject private var viewModel: ExpressTokensListViewModel

    init(viewModel: ExpressTokensListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(spacing: 14) {
            availableTokensView

            unavailableTokensView
        }
        .navigationTitle("Choose Token")
        .searchableCompat(text: $viewModel.searchText)
        .background(Colors.Background.secondary.ignoresSafeArea(.all))
    }

    private var availableTokensView: some View {
        ExpressTokensSection(title: "My tokens", items: viewModel.availableTokens) {
            SwappingTokenItemView(viewModel: $0)
                .border(Color.red)
        }
    }

    private var unavailableTokensView: some View {
        ExpressTokensSection(title: "Unavailable for swap from Bitcoin", items: viewModel.unavailableTokens) {
            SwappingTokenItemView(viewModel: $0)
        }
    }
}

struct ExpressTokensSection<Item: Identifiable, Content: View>: View {
    private let title: String
    private let items: [Item]
    private let content: (Item) -> Content

    private var horizontalPadding: CGFloat = 14

    init(
        title: String,
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.content = content
    }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.horizontal, horizontalPadding)
                
                ForEach(items) { model in
                    content(model)
                        .padding(.horizontal, horizontalPadding)
                    
                    if items.last?.id != model.id {
                        Separator(height: .minimal, color: Colors.Stroke.primary)
                            .padding(.leading, horizontalPadding)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
        }
    }
}

struct ExpressTokensListView_Preview: PreviewProvider {
    static let viewModel = ExpressTokensListViewModel(coordinator: ExpressTokensListRoutableMock())

    static var previews: some View {
        NavigationView {
            ExpressTokensListView(viewModel: viewModel)
        }
    }
}
