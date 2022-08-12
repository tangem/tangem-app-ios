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

    @Published var isSavingWallet: Bool
    @Published var isSavingAccessCodes: Bool
    @Published var alert: AlertBinder?
    @Published var isBiometryAvailable: Bool = false

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true
    private let cardModel: CardViewModel

    init(coordinator: AppSettingsRoutable, cardModel: CardViewModel) {
        self.coordinator = coordinator

        let isSavingWallet = (AppSettings.shared.saveUserWallets == true)
        self.isSavingWallet = isSavingWallet
        self.isSavingAccessCodes = isSavingWallet && AppSettings.shared.saveAccessCodes
        self.cardModel = cardModel

        bind()
        updateBiometricWarning()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func bind() {
        $isSavingWallet
            .dropFirst()
            .sink { [weak self, cardModel] saveWallet in
                if saveWallet {
                    self?.userWalletListService.tryToAccessBiometry { result in
                        if case .success = result {
                            let _ = self?.userWalletListService.save(cardModel.userWallet)
                            self?.setSaveWallets(true)
                        } else {
                            self?.setSaveWallets(false)
                        }
                    }
                } else {
                    self?.presentSavingWalletDeleteAlert()
                }
            }
            .store(in: &bag)

        $isSavingAccessCodes
            .dropFirst()
            .sink { [weak self] saveAccessCodes in
                if saveAccessCodes {
                    self?.setSaveAccessCodes(true)
                } else {
                    self?.presentSavingAccessCodesDeleteAlert()
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
                self?.isSavingWallet = true
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
        guard shouldShowAlertOnDisableSaveAccessCodes else { return }

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
            setSaveAccessCodes(false)
            userWalletListService.clear()
        }
    }

    func setSaveAccessCodes(_ saveAccessCodes: Bool) {
        AppSettings.shared.saveAccessCodes = saveAccessCodes

        if saveAccessCodes {
            withAnimation {
                isSavingWallet = true
            }
        } else {
            shouldShowAlertOnDisableSaveAccessCodes = false
            isSavingAccessCodes = false
            shouldShowAlertOnDisableSaveAccessCodes = true

            // [REDACTED_TODO_COMMENT]
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
