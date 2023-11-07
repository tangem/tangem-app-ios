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
    
    private var isEmpty: Bool {
        viewModel.availableTokens.isEmpty && viewModel.unavailableTokens.isEmpty
    }

    var body: some View {
        ZStack(alignment: .center) {
            Colors.Background.secondary.ignoresSafeArea(.all)
            
            content
        }
        .navigationTitle("Choose Token")
        .searchableCompat(text: $viewModel.searchText)
    }
    
    @ViewBuilder
    private var content: some View {
        if isEmpty {
            emptyContent
        } else {
            listContent
        }
    }
    
    private var emptyContent: some View {
        VStack(spacing: 16) {
            Assets.emptyTokenList.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)
            
            Text("You don't have any added tokens yet. Add tokens via Market to swap")
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 50)
        }
    }
    
    private var listContent: some View {
        GroupedScrollView(spacing: 14) {
            section(title: "My tokens", viewModels: viewModel.availableTokens)
            
            section(title: "Unavailable for swap from Bitcoin", viewModels: viewModel.unavailableTokens)
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

struct ExpressTokensListView_Preview: PreviewProvider {
    static let viewModel = ExpressTokensListViewModel(coordinator: ExpressTokensListRoutableMock())

    static var previews: some View {
        NavigationView {
            ExpressTokensListView(viewModel: viewModel)
        }
    }
}
