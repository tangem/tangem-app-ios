//
//  AppSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class AppSettingsViewModel: ObservableObject {
    // MARK: ViewState

    @Published var warningViewModel: DefaultWarningRowViewModel?
    @Published var savingWalletViewModel: DefaultToggleRowViewModel?
    @Published var savingAccessCodesViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var isBiometryAvailable: Bool = true

    private var isSavingWallet: Bool = true {
        didSet { self.savingWalletViewModel?.update(isOn: isSavingWalletBinding()) }
    }

    private var isSavingAccessCodes: Bool = true {
        didSet { self.savingAccessCodesViewModel?.update(isOn: isSavingAccessCodesBinding()) }
    }

    init(coordinator: AppSettingsRoutable) {
        self.coordinator = coordinator

        updateBiometricWarning()
        setupView()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func setupView() {
        if !isBiometryAvailable {
            warningViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "app_settings_warning_title".localized,
                subtitle: "app_settings_warning_subtitle".localized,
                action: openSettings
            )
        }

        savingWalletViewModel = DefaultToggleRowViewModel(
            title: "app_settings_saved_wallet".localized,
            isDisabled: !isBiometryAvailable,
            isOn: isSavingWalletBinding()
        )

        savingAccessCodesViewModel = DefaultToggleRowViewModel(
            title: "app_settings_saved_access_codes".localized,
            isDisabled: !isBiometryAvailable,
            isOn: isSavingAccessCodesBinding()
        )
    }

    func isSavingWalletBinding() -> Binding<Bool> {
        Binding<Bool>(
            root: self,
            default: false,
            get: { $0.isSavingWallet },
            set: { root, newValue in
                if newValue {
                    root.isSavingWallet = newValue
                } else {
                    root.presentSavingWalletDeleteAlert()
                }
            }
        )
    }

    func isSavingAccessCodesBinding() -> Binding<Bool> {
        Binding<Bool>(
            root: self,
            default: false,
            get: { $0.isSavingAccessCodes },
            set: { root, newValue in
                if newValue {
                    root.isSavingAccessCodes = newValue
                } else {
                    root.presentSavingAccessCodesDeleteAlert()
                }
            }
        )
    }

    func presentSavingWalletDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete"), action: { [weak self] in
            self?.disableSaveWallet()
        })
        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSavingWallet = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("app_settings_off_saved_wallet_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentSavingAccessCodesDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete"), action: { [weak self] in
            self?.disableSaveAccessCodes()
        })

        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSavingAccessCodes = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("app_settings_off_saved_access_code_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func disableSaveWallet() {
        // [REDACTED_TODO_COMMENT]
        isSavingWallet = false
        disableSaveAccessCodes()
    }

    func disableSaveAccessCodes() {
        // [REDACTED_TODO_COMMENT]

        if isSavingAccessCodes {
            isSavingAccessCodes = false
        }
    }

    func updateBiometricWarning() {
        isBiometryAvailable = BiometricAuthorizationUtils.getBiometricState() == .available

        if !isBiometryAvailable {
            isSavingWallet = false
            isSavingAccessCodes = false
        }
    }
}

// MARK: - Navigation

extension AppSettingsViewModel {
    func openTokenSynchronization() {
        coordinator.openTokenSynchronization()
    }

    func openResetSavedCards() {
        coordinator.openResetSavedCards()
    }

    func openSettings() {
        coordinator.openAppSettings()
    }
}
