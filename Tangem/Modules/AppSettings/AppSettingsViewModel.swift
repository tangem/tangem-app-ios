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
    @Published var warningSection: [DefaultWarningRowViewModel] = []
    @Published var savingWalletSection: [DefaultToggleRowViewModel] = []
    @Published var savingAccessCodesSection: [DefaultToggleRowViewModel] = []
    
    @Published var alert: AlertBinder?
    
    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true
    private var isSavingWallet: Bool = true
    private var isSavingAccessCodes: Bool = true
    private var isBiometryAvailable: Bool = true

    init(coordinator: AppSettingsRoutable) {
        self.coordinator = coordinator

        setupView()
        bind()
        updateBiometricWarning()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func setupView() {
        if isBiometryAvailable {
            warningSection = [
                DefaultWarningRowViewModel(
                    icon: Assets.attention,
                    title: "app_settings_warning_title".localized,
                    subtitle: "app_settings_warning_subtitle".localized,
                    action: openSettings
                )
            ]
        }

        savingWalletSection = [DefaultToggleRowViewModel(
            title: "app_settings_saved_wallet".localized,
            isEnabled: isBiometryAvailable,
            isOn: .init(get: { [weak self] in
                self?.isSavingWallet ?? false
            }, set: { [weak self] newValue in
                if !newValue {
                    self?.presentSavingWalletDeleteAlert()
                }
            })
        )]
        
        savingAccessCodesSection = [DefaultToggleRowViewModel(
            title: "app_settings_saved_access_codes".localized,
            isEnabled: isBiometryAvailable,
            isOn: .init(get: { [weak self] in
                self?.isSavingAccessCodes ?? false
            }, set: { [weak self] newValue in
                if !newValue {
                    self?.presentSavingAccessCodesDeleteAlert()
                }
            })
        )]
    }
    
    func bind() {
//        $isSavingWallet
//            .dropFirst()
//            .filter { !$0 }
//            .sink(receiveValue: { [weak self] _ in
//                self?.presentSavingWalletDeleteAlert()
//            })
//            .store(in: &bag)
//
//        $isSavingAccessCodes
//            .dropFirst()
//            .filter { !$0 }
//            .sink(receiveValue: { [weak self] _ in
//                self?.presentSavingAccessCodesDeleteAlert()
//            })
//            .store(in: &bag)
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
        guard shouldShowAlertOnDisableSaveAccessCodes else { return }

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
        disableSaveAccessCodes()
    }

    func disableSaveAccessCodes() {
        // [REDACTED_TODO_COMMENT]

        if isSavingAccessCodes {
            shouldShowAlertOnDisableSaveAccessCodes = false
            isSavingAccessCodes = false
            shouldShowAlertOnDisableSaveAccessCodes = true
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
