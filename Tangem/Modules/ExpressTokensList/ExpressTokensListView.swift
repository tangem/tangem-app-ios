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
        NavigationView {
            ZStack(alignment: .center) {
                Colors.Background.secondary.ignoresSafeArea(.all)

                content
            }
            .navigationTitle(Localization.swappingTokenListTitle)
            .searchableCompat(text: $viewModel.searchText)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            EmptyView()
        case .isEmpty:
            emptyContent
        case .loaded(let availableTokens, let unavailableTokens):
            listContent(availableTokens: availableTokens, unavailableTokens: unavailableTokens)
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 16) {
            Assets.emptyTokenList.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.exchangeTokensEmptyTokens)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 50)
        }
    }

    private func listContent(availableTokens: [ExpressTokenItemViewModel], unavailableTokens: [ExpressTokenItemViewModel]) -> some View {
        GroupedScrollView(spacing: 14) {
            section(title: Localization.exchangeTokensAvailableTokensHeader, viewModels: availableTokens)

            section(title: viewModel.unavailableSectionHeader, viewModels: unavailableTokens)
        }
    }

    @ViewBuilder
    private func section(title: String, viewModels: [ExpressTokenItemViewModel]) -> some View {
        if !viewModels.isEmpty {
            let horizontalPadding: CGFloat = 14
            VStack(alignment: .leading, spacing: .zero) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 12)

                ForEach(viewModels) { viewModel in
                    ExpressTokenItemView(viewModel: viewModel)
                        .padding(.horizontal, horizontalPadding)

                    if viewModels.last?.id != viewModel.id {
                        Separator(height: .minimal, color: Colors.Stroke.primary)
                            .padding(.leading, horizontalPadding)
                    }
                }
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
        }
    }
}

/*
 struct ExpressTokensListView_Preview: PreviewProvider {
     static let viewModel = ExpressTokensListViewModel(coordinator: ExpressTokensListRoutableMock())

     static var previews: some View {
          ExpressTokensListView(viewModel: viewModel)
     }
 }
 */
