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
    @Published private(set) var state: LoadingResult<GeoSelectionSections, any Error> = .loading
    @Published private(set) var countries: [TangemPayGeoCountry] = []

    let configuration: GeoSelectionConfiguration

    private let store: TangemPayGeoStore
    private let output: (Output) -> Void

    init(
        store: TangemPayGeoStore,
        configuration: GeoSelectionConfiguration,
        output: @escaping (Output) -> Void
    ) {
        self.store = store
        self.configuration = configuration
        self.output = output

        bind()
        store.loadCountries()
    }

    func onItemTap(id: String) {
        guard let country = countries.first(where: {
            $0.code == id
        }) else {
            return
        }

        output(.selected(country))
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
        case selected(TangemPayGeoCountry)
        case closed
    }
}

// MARK: - Binding

private extension CountrySelectionViewModel {
    func bind() {
        store.countriesPublisher
            .map { $0.value ?? [] }
            .receiveOnMain()
            .assign(to: &$countries)

        Publishers.CombineLatest(store.countriesPublisher, $searchText)
            .map { [configuration] state, searchText in
                state.mapValue { countries in
                    Self.makeSections(from: countries, searchText: searchText, configuration: configuration)
                }
            }
            .receiveOnMain()
            .assign(to: &$state)
    }

    static func makeSections(
        from countries: [TangemPayGeoCountry],
        searchText: String,
        configuration: GeoSelectionConfiguration
    ) -> GeoSelectionSections {
        let query = searchText.trimmed()

        let filtered = countries
            .filter { query.isEmpty || matches($0, query: query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let highlighted: TangemPayGeoCountry? = switch configuration.highlight {
        case .none: nil
        case .suggested: filtered.first(where: \.suggested)
        case .selected(let code, _, _): filtered.first { $0.code == code }
        }

        return GeoSelectionSections(
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
