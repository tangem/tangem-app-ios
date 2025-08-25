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
    @Published var searchText: String = ""
    @Published var onboardNotification: NotificationViewInput?
    @Published var items: [SendReceiveTokensListTokenViewData] = []
    @Published var isFocused: Bool = false

    var canFetchMore: Bool {
        loader.canFetchMore
    }

    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var router: SendReceiveTokensListViewRoutable?

    private lazy var loader = TokensListDataLoader(supportedBlockchains: SupportedBlockchains.all)
    private var bag: Set<AnyCancellable> = []

    init(sourceTokenInput: SendSourceTokenInput, router: SendReceiveTokensListViewRoutable) {
        self.sourceTokenInput = sourceTokenInput
        self.router = router

        bind()
        setupNotification()
    }

    func dismiss() {
        router?.closeTokensList()
    }

    func fetchMore() {
        loader.fetchMore()
    }

    private func setupNotification() {
        guard !AppSettings.shared.isSendWithSwapOnboardNotificationHidden else {
            return
        }

        onboardNotification = NotificationsFactory().buildNotificationInput(
            for: SendReceiveTokensListNotification.sendWithSwapInfo,
            dismissAction: { [weak self] _ in
                self?.onboardNotification = nil
                AppSettings.shared.isSendWithSwapOnboardNotificationHidden = true
            }
        )
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
                items.compactMap { viewModel.mapToReceiveTokensListTokenViewModel(coin: $0) }
            }
            .receiveOnMain()
            .assign(to: &$items)
    }

    private func loadTokens(searchText: String) {
        loader.fetch(searchText)
    }

    private func mapToReceiveTokensListTokenViewModel(coin: CoinModel) -> SendReceiveTokensListTokenViewData? {
        let items = coin.items.map { $0.tokenItem }.filter { tokenItem -> Bool in

            let isSameAsSource = switch (sourceTokenInput?.sourceToken.tokenItem, tokenItem) {
            case (.blockchain(let lhs), .blockchain(let rhs)): lhs.blockchain.coinId == rhs.blockchain.coinId
            case (.token(let lhs, _), .token(let rhs, _)): lhs.contractAddress == rhs.contractAddress
            default: false
            }

            // Filter source item
            return !isSameAsSource
        }

        guard !items.isEmpty else {
            return nil
        }

        return SendReceiveTokensListTokenViewData(
            id: coin.id,
            iconURL: IconURLBuilder().tokenIconURL(id: coin.id, size: .large),
            name: coin.name,
            symbol: coin.symbol
        ) { [weak self] in
            self?.openNetworkSelector(items: items)
        }
    }

    private func openNetworkSelector(items: [TokenItem]) {
        isFocused = false
        router?.openNetworkSelector(networks: items)
    }
}
