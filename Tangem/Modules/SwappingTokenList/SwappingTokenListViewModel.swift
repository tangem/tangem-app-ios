//
//  SwappingTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class SwappingTokenListViewModel: ObservableObject, Identifiable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - ViewState

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var searchText = CurrentValueSubject<String, Never>("")

    @Published var navigationTitleViewModel: BlockchainNetworkNavigationTitleViewModel?
    @Published var userItems: [SwappingTokenItemViewModel] = []
    @Published var otherItems: [SwappingTokenItemViewModel] = []

    var hasNextPage: Bool {
        dataLoader.canFetchMore
    }

    // MARK: - Dependencies

    private let userCurrenciesProvider: UserCurrenciesProviding
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let currencyMapper: CurrencyMapping
    private let walletDataProvider: SwappingWalletDataProvider
    private let fiatRatesProvider: FiatRatesProviding
    private unowned let coordinator: SwappingTokenListRoutable

    private let sourceCurrency: Currency
    private var userCurrencies: [Currency] = []
    private var bag: Set<AnyCancellable> = []
    private lazy var dataLoader: ListDataLoader = setupLoader()

    init(
        sourceCurrency: Currency,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        currencyMapper: CurrencyMapping,
        walletDataProvider: SwappingWalletDataProvider,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingTokenListRoutable
    ) {
        self.sourceCurrency = sourceCurrency
        self.userCurrenciesProvider = userCurrenciesProvider
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.currencyMapper = currencyMapper
        self.walletDataProvider = walletDataProvider
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        setupNavigationTitleView()
        setupUserItemsSection()
        bind()
        fetch()
    }

    func fetch() {
        dataLoader.fetch(searchText.value)
    }
}

private extension SwappingTokenListViewModel {
    func setupNavigationTitleView() {
        navigationTitleViewModel = .init(
            title: Localization.swappingTokenListTitle,
            iconURL: tokenIconURLBuilder.iconURL(id: sourceCurrency.blockchain.id, size: .small),
            network: sourceCurrency.blockchain.name
        )
    }

    func setupUserItemsSection() {
        runTask(in: self) { obj in
            obj.userCurrencies = await obj.userCurrenciesProvider.getCurrencies(blockchain: obj.sourceCurrency.blockchain)
            let currencies = obj.userCurrencies.filter { obj.sourceCurrency != $0 }
            var items: [SwappingTokenItemViewModel] = []
            var currenciesToLoad: [Currency] = []

            currencies.forEach { currency in
                guard let balance = obj.walletDataProvider.getBalance(for: currency),
                      let fiatBalance = obj.fiatRatesProvider.getSyncFiat(for: currency, amount: balance) else {
                    // If we haven't cache for this currency
                    currenciesToLoad.append(currency)
                    return
                }

                let viewModel = obj.mapToSwappingTokenItemViewModel(
                    currency: currency,
                    balance: CurrencyAmount(value: balance, currency: currency),
                    fiatBalance: fiatBalance
                )

                items.append(viewModel)
            }

            await runOnMain {
                obj.userItems = items
            }

            guard !currenciesToLoad.isEmpty else {
                // All currencies balances was loaded
                return
            }

            AppLog.shared.debug("Start loading balances for currencies: \(currenciesToLoad)")

            let balances = await withTaskGroup(of: (currency: Currency, balance: Decimal)?.self, returning: [Currency: Decimal].self) { taskGroup in
                currenciesToLoad.forEach { currency in
                    taskGroup.addTask {
                        do {
                            let balance = try await obj.walletDataProvider.getBalance(for: currency)
                            return (currency: currency, balance: balance)
                        } catch {
                            AppLog.shared.debug("Loading balance for currency \(currency) throw error")
                            AppLog.shared.error(error)
                            return nil
                        }
                    }
                }

                return await taskGroup.reduce(into: [:]) { partialResult, taskResult in
                    if let taskResult {
                        partialResult[taskResult.currency] = taskResult.balance
                    }
                }
            }

            let fiatBalances = try await obj.fiatRatesProvider.getFiat(for: balances)
            fiatBalances.forEach { currency, fiatBalance in
                guard let balance = balances[currency] else {
                    AppLog.shared.debug("Balance for currency \(currency) not found")
                    return
                }

                let viewModel = obj.mapToSwappingTokenItemViewModel(
                    currency: currency,
                    balance: CurrencyAmount(value: balance, currency: currency),
                    fiatBalance: fiatBalance
                )

                items.append(viewModel)
            }

            await runOnMain {
                obj.userItems = items
            }
        }
    }

    func bind() {
        searchText
            .dropFirst()
            .map { $0.trimmed() }
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] string in
                self?.dataLoader.fetch(string)
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
        Analytics.log(event: .swapSearchedTokenClicked, params: [.token: currency.symbol])
        coordinator.userDidTap(currency: currency)
    }

    func mapToSwappingTokenItemViewModel(
        currency: Currency,
        balance: CurrencyAmount? = nil,
        fiatBalance: Decimal? = nil
    ) -> SwappingTokenItemViewModel {
        SwappingTokenItemViewModel(
            tokenId: currency.id,
            iconURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
            name: currency.name,
            symbol: currency.symbol,
            balance: balance,
            fiatBalance: fiatBalance
        ) { [weak self] in
            self?.userDidTap(currency)
        }
    }
}
