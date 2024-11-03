//
//  OnrampCountrySelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class OnrampCountrySelectorViewModel: Identifiable, ObservableObject {
    let preferenceCountry: OnrampCountry?
    @Published var searchText: String = ""
    @Published private(set) var countries: [OnrampCountry] = []

    private let repository: OnrampRepository
    private weak var coordinator: OnrampCountrySelectorRoutable?

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCountrySelectorRoutable
    ) {
        self.repository = repository
        self.coordinator = coordinator

        preferenceCountry = repository.preferenceCountry

        Publishers.CombineLatest(
            dataRepository.countriesPublisher,
            $searchText.eraseError()
        )
        .map { items, searchText in
            SearchUtil.search(
                items,
                in: \.identity.name,
                for: searchText
            )
        }
        .catch { error in
            // [REDACTED_TODO_COMMENT]
            return Just([])
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$countries)
    }

    func onSelect(country: OnrampCountry) {
        repository.updatePreference(country: country)
        coordinator?.dismissCountrySelector()
    }
}
