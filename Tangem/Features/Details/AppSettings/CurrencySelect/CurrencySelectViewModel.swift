//
//  CurrencySelectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class CurrencySelectViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private weak var coordinator: CurrencySelectRoutable?

    private var loadedCurrencies = [CurrencySelectViewState.CurrencyItem]()
    private var loadCurrenciesCancellable: AnyCancellable?

    @Published private(set) var state: CurrencySelectViewState

    init(coordinator: some CurrencySelectRoutable, state: CurrencySelectViewState = .initial) {
        self.coordinator = coordinator
        self.state = state
    }

    private func handle(loadedCurrenciesDTOs: [CurrenciesResponse.Currency]) {
        loadedCurrencies = loadedCurrenciesDTOs
            .map(CurrencySelectViewState.CurrencyItem.init)
            .sorted(by: CurrencySelectViewState.CurrencyItem.sortingPredicate)

        state.update(searchText: state.searchText, allCurrencies: loadedCurrencies)
    }
}

// MARK: - View events handling

extension CurrencySelectViewModel {
    func handle(viewEvent: CurrencySelectViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .currencySelected(let selectedCurrency):
            handleCurrencySelected(selectedCurrency)

        case .searchTextUpdated(let searchText):
            handleSearchTextUpdated(searchText)
        }
    }

    private func handleViewDidAppear() {
        state.contentState = .loading

        loadCurrenciesCancellable = tangemApiService
            .loadCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state.contentState = .failure(error)
                    }
                },
                receiveValue: { [weak self] currencies in
                    self?.handle(loadedCurrenciesDTOs: currencies)
                }
            )
    }

    private func handleCurrencySelected(_ selectedCurrency: CurrencySelectViewState.CurrencyItem) {
        loadedCurrencies = loadedCurrencies
            .map {
                CurrencySelectViewState.CurrencyItem(
                    code: $0.code,
                    title: $0.title,
                    isSelected: $0 == selectedCurrency
                )
            }

        state.update(searchText: state.searchText, allCurrencies: loadedCurrencies)

        Analytics.log(event: .mainCurrencyChanged, params: [.currency: selectedCurrency.title])
        AppSettings.shared.selectedCurrencyCode = selectedCurrency.code

        coordinator?.dismissCurrencySelect()
    }

    private func handleSearchTextUpdated(_ searchText: String) {
        state.update(searchText: searchText, allCurrencies: loadedCurrencies)
    }
}

// MARK: - View state mapping

private extension CurrencySelectViewState {
    mutating func update(searchText: String, allCurrencies: [CurrencySelectViewState.CurrencyItem]) {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filteredCurrencies = searchText.isEmpty
            ? allCurrencies
            : allCurrencies.filter { $0.title.localizedStandardContains(searchText) }

        contentState = .success(filteredCurrencies)
        self.searchText = searchText
    }
}

extension CurrencySelectViewState.CurrencyItem {
    init(currencyDTO: CurrenciesResponse.Currency) {
        self.init(
            code: currencyDTO.code,
            title: currencyDTO.description,
            isSelected: AppSettings.shared.selectedCurrencyCode == currencyDTO.code
        )
    }

    static func sortingPredicate(lhs: CurrencySelectViewState.CurrencyItem, rhs: CurrencySelectViewState.CurrencyItem) -> Bool {
        if lhs.isSelected != rhs.isSelected {
            return lhs.isSelected && !rhs.isSelected
        }

        return lhs.title < rhs.title
    }
}
