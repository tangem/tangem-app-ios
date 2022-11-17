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
    private let userWallet: UserWallet
    private var isBiometryAvailable: Bool = true

    private var isSavingWallet: Bool {
        didSet {
            savingWalletViewModel?.update(isOn: isSavingWalletBinding())
            AppSettings.shared.saveUserWallets = isSavingWallet
        }
    }

    private var isSavingAccessCodes: Bool {
        didSet {
            savingAccessCodesViewModel?.update(isOn: isSavingAccessCodesBinding())
            AppSettings.shared.saveAccessCodes = isSavingAccessCodes
        }
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
    func isSavingWalletRequestChange(saveWallet: Bool) {
        Analytics.log(.saveUserWalletSwitcherChanged,
                      params: [.state: Analytics.ParameterValue.state(for: saveWallet).rawValue])

        if saveWallet {
            unlockWithBiometry { [weak self] in
                self?.setSaveWallets($0)
            }
        } else {
            presentSavingWalletDeleteAlert()
        }
    }

    func unlockWithBiometry(completion: @escaping (_ success: Bool) -> Void) {
        userWalletListService.unlockWithBiometry { [weak self] result in
            guard let self else { return }

            if case .success = result {
                let _ = self.userWalletListService.save(self.userWallet)
                completion(true)
            } else {
                self.updateBiometricWarning()
                completion(false)
            }
        }
    }

    func isSavingAccessCodesRequestChange(saveAccessCodes: Bool) {
        Analytics.log(.saveAccessCodeSwitcherChanged,
                      params: [.state: Analytics.ParameterValue.state(for: saveAccessCodes).rawValue])

        if saveAccessCodes {
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
                root.isSavingWallet = newValue
                root.isSavingWalletRequestChange(saveWallet: newValue)
            }
        )
    }

    func isSavingAccessCodesBinding() -> Binding<Bool> {
        Binding<Bool>(
            root: self,
            default: false,
            get: { $0.isSavingAccessCodes },
            set: { root, newValue in
                root.isSavingAccessCodes = newValue
                root.isSavingAccessCodesRequestChange(saveAccessCodes: newValue)
            }
        )
    }

    func presentSavingWalletDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete")) { [weak self] in
            self?.setSaveWallets(false)
        }
        let cancelButton = Alert.Button.cancel(Text("common_cancel")) { [weak self] in
            self?.setSaveWallets(true)
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
            self?.setSaveAccessCodes(false)
        }

        let cancelButton = Alert.Button.cancel(Text("common_cancel")) { [weak self] in
            self?.setSaveAccessCodes(true)
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
        isSavingWallet = saveWallets

        // If saved wallets is turn off we should delete access codes too
        if !saveWallets {
            setSaveAccessCodes(false)
            userWalletListService.clear()
        }
    }

    func setSaveAccessCodes(_ saveAccessCodes: Bool) {
        if saveAccessCodes {
            // If savingWallets already on, just update settings
            if isSavingWallet {
                isSavingAccessCodes = true
            } else {
                // Otherwise saving access codes should be on after biometry authorization
                unlockWithBiometry { [weak self] success in
                    self?.setSaveWallets(success)
                    self?.isSavingAccessCodes = success
                }
            }
        } else {
            let accessCodeRepository = AccessCodeRepository()
            accessCodeRepository.clear()

            isSavingAccessCodes = false
        }
    }

    func updateBiometricWarning() {
        isBiometryAvailable = BiometricAuthorizationUtils.getBiometricState() == .available
        setupView()
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
