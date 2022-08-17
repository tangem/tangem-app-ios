//
//  TokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

enum CommonError: Error {
    case masterReleased
}

enum ContentState<Data> {
    case loading
    case empty
    case loaded(_ content: Data)
    case error(error: Error)

    var isEmpty: Bool {
        if case .empty = self {
            return true
        }

        return false
    }
}

struct WalletTokenListView: View {
    @ObservedObject private var viewModel: WalletTokenListViewModel

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel
    }

    // I hope will be redesign
    var body: some View {
        if !viewModel.contentState.isEmpty {
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
            .onAppear(perform: viewModel.onAppear)
        }
    }

    @ViewBuilder var content: some View {
        switch viewModel.contentState {
        case .loading:
            ActivityIndicatorView(color: .gray)
                .padding()

        case .empty:
            // Oops, user haven't added any tokens
            EmptyView()

        case let .loaded(viewModels):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(viewModels) { item in
                    VStack {
                        Button(action: { viewModel.tokenItemDidTap(item) }) {
                            TokenItemView(item: item)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 15)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(TangemTokenButtonStyle())

                        if viewModels.last != item {
                            Separator(height: 1, padding: 0, color: .tangemBgGray2)
                                .padding(.leading, 68)
                        }
                    }
                }
            }


        case let .error(error):
            Text(error.localizedDescription)
                .padding()
        }
    }
}


struct WalletTokenListViewModel_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            WalletTokenListView(viewModel: WalletTokenListViewModel(cardModel: .init(cardInfo: .init(card: .card, isTangemNote: false, isTangemWallet: false)), walletDidTap: { _ in

            }))
        }
        .previewLayout(.sizeThatFits)
    }
}
