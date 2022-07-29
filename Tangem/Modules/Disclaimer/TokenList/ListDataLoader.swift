//
//  ListDataLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk

class ListDataLoader {
    // MARK: Dependencies
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    // MARK: Output
    @Published var items: [CoinModel] = []

    // Tells if all items have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true

    // MARK: Input
    private let cardInfo: CardInfo?

    // MARK: Private

    // Tracks last page loaded. Used to load next page (current + 1)
    private var currentPage = 0

    // Limit of records per page
    private let perPage = 50

    private var cancellable: AnyCancellable?

    private var cached: [CoinModel] = []
    private var cachedSearch: [String: [CoinModel]] = [:]
    private var lastSearchText = ""

    /// Used to filter the loading of available coins
    private var walletCurves: [EllipticCurve] {
        cardInfo?.card.walletCurves ?? EllipticCurve.allCases
    }

    private var isTestnet: Bool {
        cardInfo?.isTestnet ?? false
    }

    init(cardInfo: CardInfo?) {
        self.cardInfo = cardInfo
    }

    func reset(_ searchText: String) {
        self.canFetchMore = true
        self.items = []
        self.currentPage = 0
        self.lastSearchText = searchText
        self.cachedSearch = [:]
    }

    func fetch(_ searchText: String) {
        cancellable = nil

        if lastSearchText != searchText {
            reset(searchText)
        }

        cancellable = loadItems(searchText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }

                self.currentPage += 1
                self.items.append(contentsOf: items)
                // If count of data received is less than perPage value then it is last page.
                if items.count < self.perPage {
                    self.canFetchMore = false
                }
            }
    }
}

// MARK: Private

private extension ListDataLoader {
    func loadItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        // If testnet then use local coins from testnet_tokens.json file
        if isTestnet {
            return loadTestnetItems(searchText)
        }

        return loadMainnetItems(searchText)
    }

    func loadTestnetItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let searchText = searchText.lowercased()
        let itemsPublisher: AnyPublisher<[CoinModel], Never>

        if cached.isEmpty {
            itemsPublisher = loadCoinsFromLocalJsonPublisher()
        } else {
            itemsPublisher = Just(cached).eraseToAnyPublisher()
        }

        return itemsPublisher
            .map { [weak self] models -> [CoinModel] in
                guard let self = self else { return [] }

                if searchText.isEmpty { return models }

                if let cachedSearch = self.cachedSearch[searchText] {
                    return cachedSearch
                }

                let foundItems = models.filter {
                    "\($0.name) \($0.symbol)".lowercased().contains(searchText)
                }

                self.cachedSearch[searchText] = foundItems

                return foundItems
            }
            .map { [weak self] models -> [CoinModel] in
                self?.getPage(for: models) ?? []
            }
            .eraseToAnyPublisher()
    }

    func loadMainnetItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let networkIds = SupportedTokenItems()
            .blockchains(for: walletCurves, isTestnet: isTestnet)
            .map { $0.networkId }

        let searchText = searchText.trimmed()
        let requestModel = CoinsListRequestModel(
            networkIds: networkIds,
            searchText: searchText,
            limit: perPage,
            offset: items.count,
            active: true
        )

        return tangemApiService.loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    func loadCoinsFromLocalJsonPublisher() -> AnyPublisher<[CoinModel], Never> {
        SupportedTokenItems().loadTestnetCoins(supportedCurves: walletCurves)
            .handleEvents(receiveOutput: { [weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    func getPage(for items: [CoinModel]) -> [CoinModel] {
        Array(items.dropFirst(currentPage * perPage).prefix(perPage))
    }
}
