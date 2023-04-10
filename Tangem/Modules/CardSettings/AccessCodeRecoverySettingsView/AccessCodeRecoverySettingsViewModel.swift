//
//  AccessCodeRecoverySettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

protocol AccessCodeRecoverySettingsProvider {
    var accessCodeRecoveryEnabled: Bool { get }
    func setAccessCodeRecovery(to enabled: Bool, _ completionHandler: @escaping (Result<Void, Error>) -> Void)
}

class AccessCodeRecoverySettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var viewModels: [DefaultSelectableRowViewModel<Bool>] = []
    @Published var accessCodeRecoveryEnabled: Bool
    @Published var errorAlert: AlertBinder?

    var actionButtonDisabled: Bool {
        accessCodeRecoveryEnabled == settingsProvider.accessCodeRecoveryEnabled
    }

    private let settingsProvider: AccessCodeRecoverySettingsProvider

    init(settingsProvider: AccessCodeRecoverySettingsProvider) {
        self.settingsProvider = settingsProvider
        accessCodeRecoveryEnabled = settingsProvider.accessCodeRecoveryEnabled
        setupViews()
    }

    func actionButtonDidTap() {
        isLoading = true
        settingsProvider.setAccessCodeRecovery(to: accessCodeRecoveryEnabled) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                break
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {
                    break
                }

                self.errorAlert = error.alertBinder
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func setupViews() {
        viewModels = [
            DefaultSelectableRowViewModel(
                id: true,
                title: Localization.commonEnabled,
                subtitle: Localization.cardSettingsAccessCodeRecoveryEnabledDescription
            ),
            DefaultSelectableRowViewModel(
                id: false,
                title: Localization.commonDisabled,
                subtitle: Localization.cardSettingsAccessCodeRecoveryDisabledDescription
            ),
        ]
    }
}
