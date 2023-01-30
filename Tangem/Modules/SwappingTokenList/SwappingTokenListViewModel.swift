//
//  SwappingTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExchange

final class SwappingTokenListViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id = UUID()

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - ViewState

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var searchText = CurrentValueSubject<String, Never>("")
    @Published var userItems: [SwappingTokenItemViewModel] = []
    @Published var otherItems: [SwappingTokenItemViewModel] = []

    var hasNextPage: Bool {
        dataLoader.canFetchMore
    }

    // MARK: - Dependencies

    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let currencyMapper: CurrencyMapping
    private let blockchainDataProvider: TangemExchange.BlockchainDataProvider
    private let fiatRatesProvider: FiatRatesProviding
    private unowned let coordinator: SwappingTokenListRoutable

    private let sourceCurrency: Currency
    private let userCurrencies: [Currency]
    private var bag: Set<AnyCancellable> = []
    private lazy var dataLoader: ListDataLoader = setupLoader()

    init(
        sourceCurrency: Currency,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        currencyMapper: CurrencyMapping,
        blockchainDataProvider: TangemExchange.BlockchainDataProvider,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingTokenListRoutable
    ) {
        self.sourceCurrency = sourceCurrency
        userCurrencies = userCurrenciesProvider.getCurrencies(blockchain: sourceCurrency.blockchain)
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.currencyMapper = currencyMapper
        self.blockchainDataProvider = blockchainDataProvider
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        setupUserItemsSection()
        bind()
    }

    func fetch() {
        dataLoader.fetch(searchText.value)
    }
}

private extension SwappingTokenListViewModel {
    func setupUserItemsSection() {
        userItems = userCurrencies
            .filter { sourceCurrency != $0 }
            .map { mapToSwappingTokenItemViewModel(currency: $0) }
    }

    func bind() {
        searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                self?.dataLoader.reset(string)
            }
            .store(in: &bag)
    }

    func setupLoader() -> ListDataLoader {
        let dataLoader = ListDataLoader(networkIds: [sourceCurrency.blockchain.networkId], exchangeable: true)
        dataLoader.$items
            .receive(on: DispatchQueue.global())
            .map { [weak self] coinModels in
                coinModels.compactMap { self?.currencyMapper.mapToCurrency(coinModel: $0) }
            }
            .map { [weak self] currencies in
                currencies
                    .filter { currency in self?.userCurrencies.contains(currency) == false }
                    .compactMap { self?.mapToSwappingTokenItemViewModel(currency: $0) }
            }
            .receive(on: DispatchQueue.main)
            .receiveValue { [weak self] items in
                self?.otherItems = items
            }
            .store(in: &bag)

        return dataLoader
    }

    func userDidTap(_ currency: Currency) {
        coordinator.userDidTap(currency: currency)
    }

    func mapToSwappingTokenItemViewModel(currency: Currency) -> SwappingTokenItemViewModel {
        SwappingTokenItemViewModel(
            id: currency.id,
            iconURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
            name: currency.name,
            symbol: currency.symbol,
            fiatBalance: nil,
            balance: nil
        ) { [weak self] in
            self?.userDidTap(currency)
        }
    }
}
