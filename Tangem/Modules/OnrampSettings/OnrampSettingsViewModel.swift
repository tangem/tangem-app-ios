//
//  OnrampSettingsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class OnrampSettingsViewModel: ObservableObject {
    @Published private(set) var selectedCountry: OnrampCountry?

    private weak var coordinator: OnrampSettingsRoutable?

    init(repository: OnrampRepository, coordinator: OnrampSettingsRoutable) {
        self.coordinator = coordinator
        selectedCountry = repository.preferenceCountry

        repository.preferenceCountryPublisher
            .assign(to: &$selectedCountry)
    }

    func onTapResidence() {
        coordinator?.openOnrampCountrySelector()
    }
}
