//
//  SendReceiveTokensListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemExpress

protocol SendReceiveTokensListViewRoutable: AnyObject {
    func openNetworkSelector(networks: [TokenItem])
    func closeTokensList()
}

class SendReceiveTokensListViewModel: ObservableObject, Identifiable {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var searchText: String = ""
    @Published var items: [SendReceiveTokensListTokenViewData] = []
    @Published var isFocused: Bool = false

    var canFetchMore: Bool {
        loader.canFetchMore
    }

    private weak var router: SendReceiveTokensListViewRoutable?

    private lazy var loader = TokensListDataLoader(supportedBlockchains: SupportedBlockchains.all)
    private var bag: Set<AnyCancellable> = []

    init(router: SendReceiveTokensListViewRoutable) {
        self.router = router

        bind()
    }

    func dismiss() {
        router?.closeTokensList()
    }

    func fetchMore() {
        loader.fetchMore()
    }

    private func bind() {
        $searchText
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.loadTokens(searchText: searchText)
            }
            .store(in: &bag)

        loader.$items
            .receiveOnGlobal()
            .withWeakCaptureOf(self)
            .map { viewModel, items in
                items.map { viewModel.mapToReceiveTokensListTokenViewModel(coin: $0) }
            }
            .receiveOnMain()
            .assign(to: &$items)
    }

    private func loadTokens(searchText: String) {
        loader.fetch(searchText)
    }

    private func mapToReceiveTokensListTokenViewModel(coin: CoinModel) -> SendReceiveTokensListTokenViewData {
        SendReceiveTokensListTokenViewData(
            id: coin.id,
            iconURL: IconURLBuilder().tokenIconURL(id: coin.id, size: .large),
            name: coin.name,
            symbol: coin.symbol
        ) { [weak self] in
            self?.openNetworkSelector(coin: coin)
        }
    }

    private func openNetworkSelector(coin: CoinModel) {
        isFocused = false
        router?.openNetworkSelector(networks: coin.items.map(\.tokenItem))
    }
}
