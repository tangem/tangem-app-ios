//
//  AppSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit

final class AppSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var rootViewModel: AppSettingsViewModel?
    @Published private(set) var newRootViewModel: NewAppSettingsViewModel?

    // MARK: - Child view models

    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var themeSelectionViewModel: ThemeSelectionViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        if FeatureProvider.isAvailable(.mobileWallet) {
            newRootViewModel = NewAppSettingsViewModel(coordinator: self)
        } else {
            rootViewModel = AppSettingsViewModel(coordinator: self)
        }
    }
}

// MARK: - Options

extension AppSettingsCoordinator {
    struct Options {}
}

// MARK: - AppSettingsRoutable

extension AppSettingsCoordinator: AppSettingsRoutable {
    func openTokenSynchronization() {}
    func openResetSavedCards() {}
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }

        UIApplication.shared.open(settingsUrl, completionHandler: { _ in })
    }

    func openCurrencySelection() {
        Task { @MainActor in
            currencySelectViewModel = CurrencySelectViewModel(coordinator: self)
        }
    }

    func openThemeSelection() {
        themeSelectionViewModel = ThemeSelectionViewModel()
    }
}

extension AppSettingsCoordinator: CurrencySelectRoutable {
    func dismissCurrencySelect() {
        currencySelectViewModel = nil
    }
}
