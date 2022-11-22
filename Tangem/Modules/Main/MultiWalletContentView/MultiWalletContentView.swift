//
//  MultiWalletContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletContentView: View {
    @ObservedObject private var viewModel: MultiWalletContentViewModel

    init(viewModel: MultiWalletContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if !viewModel.tokenListIsEmpty {
                TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            tokenList

            AddTokensView(action: viewModel.openTokensList)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 6)
        }
    }

    @ViewBuilder var tokenList: some View {
        if !viewModel.tokenListIsEmpty {
            VStack(alignment: .center, spacing: 0) {
                Text("main_tokens".localized)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .top], 16)

                content
            }
            .frame(maxWidth: .infinity)
            .background(Colors.Background.plain)
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder var content: some View {
        switch viewModel.contentState {
        case .loading:
            ActivityIndicatorView(color: .gray)
                .padding()

        case let .loaded(viewModels):
            LazyVStackCompat(alignment: .leading, spacing: 6) {
                ForEach(viewModels) { item in
                    VStack {
                        Button(action: { viewModel.tokenItemDidTap(item) }) {
                            TokenItemView(item: item)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 15)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(TangemTokenButtonStyle())
                        .disabled(item.state == .noDerivation)

                        if viewModels.last != item {
                            Separator(height: 1, padding: 0, color: .tangemBgGray2)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
        }
    }
}
