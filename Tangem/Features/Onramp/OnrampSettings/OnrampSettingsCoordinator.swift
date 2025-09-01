//
//  OnrampSettingsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

class OnrampSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OnrampSettingsViewModel?

    // MARK: - Child view models

    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?

    private var options: Options?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
        rootViewModel = .init(repository: options.repository, coordinator: self)
    }
}

// MARK: - Options

extension OnrampSettingsCoordinator {
    struct Options {
        let repository: any OnrampRepository
        let dataRepository: any OnrampDataRepository
    }
}

// MARK: - OnrampSettingsRoutable

extension OnrampSettingsCoordinator: OnrampSettingsRoutable {
    func openOnrampCountrySelector() {
        guard let options else {
            assertionFailure("OnrampCountryDetectionCoordinator.Options not found")
            return
        }

        onrampCountrySelectorViewModel = OnrampCountrySelectorViewModel(
            repository: options.repository,
            dataRepository: options.dataRepository,
            coordinator: self
        )
    }
}

// MARK: - OnrampCountrySelectorRoutable

extension OnrampSettingsCoordinator: OnrampCountrySelectorRoutable {
    func dismissCountrySelector() {
        onrampCountrySelectorViewModel = nil
    }
}
