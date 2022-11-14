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
    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding

    // MARK: ViewState

    @Published var warningViewModel: DefaultWarningRowViewModel?
    @Published var savingWalletViewModel: DefaultToggleRowViewModel?
    @Published var savingAccessCodesViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var ignoreSaveWalletChanges = false
    private var ignoreSaveAccessCodeChanges: Bool = false
    private let userWallet: UserWallet
    private var isBiometryAvailable: Bool = true

    private var isSavingWallet: Bool = true {
        didSet { isSavingWalletDidChange() }
    }

    private var isSavingAccessCodes: Bool = true {
        didSet { isSavingAccessCodesDidChange() }
    }

    init(coordinator: AppSettingsRoutable, userWallet: UserWallet) {
        self.coordinator = coordinator

        let isSavingWallet = AppSettings.shared.saveUserWallets
        self.isSavingWallet = isSavingWallet
        self.isSavingAccessCodes = isSavingWallet && AppSettings.shared.saveAccessCodes
        self.userWallet = userWallet

        updateBiometricWarning()
        setupView()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func isSavingWalletDidChange() {
        self.savingWalletViewModel?.update(isOn: isSavingWalletBinding())

        if self.ignoreSaveWalletChanges {
            return
        }

        Analytics.log(.saveUserWalletSwitcherChanged,
                      params: [.state: Analytics.ParameterValue.state(for: isSavingWallet).rawValue])

        if isSavingWallet {
            self.userWalletListService.unlockWithBiometry { [weak self] result in
                guard let self else { return }
                if case .success = result {
                    self.userWalletListService.save(self.userWallet)
                    self.setSaveWallets(true)
                } else {
                    self.updateBiometricWarning()
                    self.setSaveWallets(false)
                }
            }
        } else {
            self.presentSavingWalletDeleteAlert()
        }
    }

    func isSavingAccessCodesDidChange() {
        self.savingAccessCodesViewModel?.update(isOn: isSavingAccessCodesBinding())

        if self.ignoreSaveAccessCodeChanges {
            return
        }

        Analytics.log(.saveAccessCodeSwitcherChanged,
                      params: [.state: Analytics.ParameterValue.state(for: isSavingAccessCodes).rawValue])

        if isSavingAccessCodes {
            self.setSaveAccessCodes(true)
        } else {
            self.presentSavingAccessCodesDeleteAlert()
        }
    }

    func setupView() {
        if !isBiometryAvailable {
            warningViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "app_settings_warning_title".localized,
                subtitle: "app_settings_warning_subtitle".localized,
                action: openBiometrySettings
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

    func openBiometrySettings() {
        Analytics.log(.buttonEnableBiometricAuthentication)
        coordinator.openAppSettings()
    }
}
