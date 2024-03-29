//
//  ExpressTokensListView.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressTokensListView: View {
    @ObservedObject private var viewModel: ExpressTokensListViewModel

    init(viewModel: ExpressTokensListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Colors.Background.tertiary.ignoresSafeArea(.all)

            mainContent
        }
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: .zero) {
            BottomSheetSearchableHeaderView(
                title: Localization.swappingTokenListTitle,
                searchText: $viewModel.searchText
            )
            .padding(.vertical, 12)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            EmptyView()
        case .isEmpty:
            emptyContent
        case .loaded(let availableTokens, let unavailableTokens):
            GroupedScrollView(alignment: .leading, spacing: 14) {
                if availableTokens.isEmpty, unavailableTokens.isEmpty {
                    emptySearchContent
                } else {
                    section(title: Localization.exchangeTokensAvailableTokensHeader, viewModels: availableTokens)

                    section(title: viewModel.unavailableSectionHeader, viewModels: unavailableTokens)
                }
            }
        }
    }

    private var emptyContent: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(spacing: 16) {
                Assets.emptyTokenList.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.inactive)

                Text(Localization.exchangeTokensEmptyTokens)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.horizontal, 50)
            }

            Spacer()
        }
    }

    private var emptySearchContent: some View {
        Text(Localization.expressTokenListEmptySearch)
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .padding(.all, 14)
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
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
        }
    }
}

struct ExpressTokensListView_Preview: PreviewProvider {
    static let viewModel = ExpressModulesFactoryMock().makeExpressTokensListViewModel(
        swapDirection: .fromSource(.mockETH),
        coordinator: ExpressTokensListRoutableMock()
    )

    static var previews: some View {
        ExpressTokensListView(viewModel: viewModel)
    }
}
