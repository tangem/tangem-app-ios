//
//  TokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class WalletTokenListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var tokenViewModels: [TokenItemViewModel]

    // MARK: - Private

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private let walletDidTap: (TokenItemViewModel) -> ()

    init(cachedWallets: [WalletModel], walletDidTap: @escaping (TokenItemViewModel) -> ()) {
        self.walletDidTap = walletDidTap
        self.tokenViewModels = cachedWallets.first?.tokenItemViewModels ?? []
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        walletDidTap(wallet)
    }

    func updateTokenViewModels(_ models: [TokenItemViewModel]) {
        self.tokenViewModels = models
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func bind() {
//        tangemApiService.loadCoins(requestModel: <#T##CoinsListRequestModel#>)
//        [REDACTED_TODO_COMMENT]
    }
}

struct WalletTokenListView: View {
    @ObservedObject private var viewModel: WalletTokenListViewModel

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel
    }

    // I hope will be redesign
    var body: some View {
        if !viewModel.tokenViewModels.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("main_tokens".localized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                    .padding([.leading, .top], 16)

                ForEach(viewModel.tokenViewModels) { item in
                    VStack {
                        Button(action: { viewModel.tokenItemDidTap(item) }) {
                            TokenItemView(item: item)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 15)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(TangemTokenButtonStyle())

                        if viewModel.tokenViewModels.last != item {
                            Separator(height: 1, padding: 0, color: .tangemBgGray2)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
}
