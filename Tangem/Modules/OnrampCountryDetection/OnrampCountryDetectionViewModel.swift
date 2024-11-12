//
//  OnrampCountryDetectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class OnrampCountryDetectionViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    let iconURL: URL?
    let title: String
    let style: Subtitle

    var mainButtonTitle: String {
        style == .info ? Localization.commonConfirm : Localization.commonClose
    }

    // MARK: - Dependencies

    private let country: OnrampCountry
    private let repository: OnrampRepository
    private weak var coordinator: OnrampCountryDetectionRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        country: OnrampCountry,
        repository: OnrampRepository,
        coordinator: OnrampCountryDetectionRoutable
    ) {
        iconURL = country.identity.image
        title = country.identity.name
        style = country.onrampAvailable ? .info : .notSupport

        self.country = country
        self.repository = repository
        self.coordinator = coordinator

        bind()
    }

    func didTapChangeButton() {
        coordinator?.openChangeCountry()
    }

    func didTapMainButton() {
        switch style {
        case .info:
            repository.updatePreference(country: country, currency: country.currency)
            coordinator?.dismissConfirmCountryView()
        case .notSupport:
            coordinator?.dismiss()
        }
    }
}

// MARK: - Private

private extension OnrampCountryDetectionViewModel {
    func bind() {}
}

extension OnrampCountryDetectionViewModel {
    enum Subtitle: Hashable {
        case info
        case notSupport
    }
}
