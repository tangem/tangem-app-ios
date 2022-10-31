//
//  AppSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class AppSettingsViewModel: ObservableObject {
    // MARK: ViewState

    @Published var isSavingWallet: Bool
    @Published var isSavingAccessCodes: Bool
    @Published var alert: AlertBinder?
    @Published var isBiometryAvailable: Bool = false

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var ignoreSaveWalletChanges = false
    private var ignoreSaveAccessCodeChanges: Bool = false
    private let userWallet: UserWallet

    init(coordinator: AppSettingsRoutable, userWallet: UserWallet) {
        self.coordinator = coordinator

        let isSavingWallet = AppSettings.shared.saveUserWallets
        self.isSavingWallet = isSavingWallet
        self.isSavingAccessCodes = isSavingWallet && AppSettings.shared.saveAccessCodes
        self.userWallet = userWallet

        bind()
        updateBiometricWarning()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func bind() {
        $isSavingWallet
            .dropFirst()
            .sink { [weak self, userWallet] saveWallet in
                guard let self = self else { return }

                if self.ignoreSaveWalletChanges {
                    return
                }

                if saveWallet {
                    self.userWalletListService.unlockWithBiometry { result in
                        if case .success = result {
                            let _ = self.userWalletListService.save(userWallet)
                            self.setSaveWallets(true)
                        } else {
                            self.setSaveWallets(false)
                        }
                    }
                } else {
                    self.presentSavingWalletDeleteAlert()
                }
            }
            .store(in: &bag)

        $isSavingAccessCodes
            .dropFirst()
            .sink { [weak self] saveAccessCodes in
                guard let self = self else { return }

                if self.ignoreSaveAccessCodeChanges {
                    return
                }

                if saveAccessCodes {
                    self.setSaveAccessCodes(true)
                } else {
                    self.presentSavingAccessCodesDeleteAlert()
                }
            }
            .store(in: &bag)
    }

    func presentSavingWalletDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete")) { [weak self] in
            withAnimation {
                self?.setSaveWallets(false)
            }
        }
        let cancelButton = Alert.Button.cancel(Text("common_cancel")) { [weak self] in
            withAnimation {
                self?.setSaveWallets(true)

                self?.ignoreSaveWalletChanges = true
                self?.isSavingWallet = true
                self?.ignoreSaveWalletChanges = false
            }
        }

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("app_settings_off_saved_wallet_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentSavingAccessCodesDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete")) { [weak self] in
            withAnimation {
                self?.setSaveAccessCodes(false)
            }
        }
        let cancelButton = Alert.Button.cancel(Text("common_cancel")) { [weak self] in
            withAnimation {
                self?.setSaveAccessCodes(true)
                self?.isSavingAccessCodes = true
            }
        }

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("app_settings_off_saved_access_code_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func setSaveWallets(_ saveWallets: Bool) {
        AppSettings.shared.saveUserWallets = saveWallets

        if !saveWallets {
            withAnimation {
                ignoreSaveWalletChanges = true
                isSavingWallet = false
                ignoreSaveWalletChanges = false
            }

            setSaveAccessCodes(false)
            userWalletListService.clear()
        }
    }

    func setSaveAccessCodes(_ saveAccessCodes: Bool) {
        AppSettings.shared.saveAccessCodes = saveAccessCodes

        withAnimation {
            if saveAccessCodes {
                if !isSavingWallet {
                    isSavingWallet = true
                }
            } else {
                ignoreSaveAccessCodeChanges = true
                isSavingAccessCodes = false
                ignoreSaveAccessCodeChanges = false

                let accessCodeRepository = AccessCodeRepository()
                accessCodeRepository.clear()
            }
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
