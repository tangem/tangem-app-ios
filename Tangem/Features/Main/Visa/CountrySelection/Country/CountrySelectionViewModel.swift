//
//  CountrySelectionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

@MainActor
final class CountrySelectionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var state: LoadingResult<GeoSelectionList, any Error> = .loading
    @Published private(set) var loadingItemId: String?
    @Published private(set) var countries: [TangemPayGeoCountry] = []

    let configuration: GeoSelectionConfiguration

    private let store: TangemPayGeoStore
    private let output: (Output) -> Void

    init(
        store: TangemPayGeoStore,
        configuration: GeoSelectionConfiguration,
        loadingItemIdPublisher: AnyPublisher<String?, Never> = Just(nil).eraseToAnyPublisher(),
        output: @escaping (Output) -> Void
    ) {
        self.store = store
        self.configuration = configuration
        self.output = output

        bind(loadingItemIdPublisher: loadingItemIdPublisher)
        store.loadCountries()
    }

    func onItemTap(id: String, isHighlighted: Bool) {
        guard loadingItemId == nil, let country = countries.first(where: {
            $0.code == id
        }) else {
            return
        }

        output(.selected(country, isHighlighted: isHighlighted))
    }

    func onRetryTap() {
        store.reloadCountries()
    }

    func onClose() {
        output(.closed)
    }
}

// MARK: - Output

extension CountrySelectionViewModel {
    enum Output {
        case selected(TangemPayGeoCountry, isHighlighted: Bool)
        case closed
    }
}

// MARK: - Binding

private extension CountrySelectionViewModel {
    func bind(loadingItemIdPublisher: AnyPublisher<String?, Never>) {
        loadingItemIdPublisher
            .receiveOnMain()
            .assign(to: &$loadingItemId)

        store.countriesPublisher
            .map { $0.value ?? [] }
            .receiveOnMain()
            .assign(to: &$countries)

        Publishers.CombineLatest(store.countriesPublisher, $searchText)
            .map { [configuration] state, searchText in
                state.mapValue { countries in
                    Self.makeList(from: countries, searchText: searchText, configuration: configuration)
                }
            }
            .receiveOnMain()
            .assign(to: &$state)
    }

    static func makeList(
        from countries: [TangemPayGeoCountry],
        searchText: String,
        configuration: GeoSelectionConfiguration
    ) -> GeoSelectionList {
        let query = searchText.trimmed()

        let filtered = countries
            .filter { query.isEmpty || matches($0, query: query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        guard query.isEmpty else {
            return .searchResults(filtered.map(makeItem(from:)))
        }

        let highlighted: TangemPayGeoCountry? = switch configuration.highlight {
        case .none: nil
        case .suggested: filtered.first(where: \.suggested)
        case .selected(let code, _, _): filtered.first { $0.code == code }
        }

        return .sections(
            highlighted: highlighted.map(makeItem(from:)),
            all: filtered.map(makeItem(from:))
        )
    }

    static func matches(_ country: TangemPayGeoCountry, query: String) -> Bool {
        country.name.caseInsensitiveContains(query) || country.code.caseInsensitiveHasPrefix(query)
    }

    static func makeItem(from country: TangemPayGeoCountry) -> GeoSelectionItem {
        GeoSelectionItem(
            id: country.code,
            title: country.name,
            flagURL: country.flagUrl.flatMap(URL.init(string:))
        )
    }
}
