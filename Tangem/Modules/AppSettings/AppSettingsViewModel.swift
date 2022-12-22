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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
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

    init(userWallet: UserWallet, coordinator: AppSettingsRoutable) {
        self.coordinator = coordinator

        let isSavingWallet = AppSettings.shared.saveUserWallets
        self.isSavingWallet = isSavingWallet
        self.isSavingAccessCodes = isSavingWallet && AppSettings.shared.saveAccessCodes
        self.userWallet = userWallet

        updateView()
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
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            guard let self else { return }

            if case .error = result {
                self.updateView()
                completion(false)
            } else {
                let _ = self.userWalletRepository.save(self.userWallet)
                completion(true)
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
                title: Localization.appSettingsWarningTitle,
                subtitle: Localization.appSettingsWarningSubtitle,
                action: openBiometrySettings
            )
        }

        savingWalletViewModel = DefaultToggleRowViewModel(
            title: Localization.appSettingsSavedWallet,
            isDisabled: !isBiometryAvailable,
            isOn: isSavingWalletBinding()
        )

        savingAccessCodesViewModel = DefaultToggleRowViewModel(
            title: Localization.appSettingsSavedAccessCodes,
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
        let okButton = Alert.Button.destructive(Text(Localization.commonDelete)) { [weak self] in
            self?.setSaveWallets(false)
        }
        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setSaveWallets(true)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsOffSavedWalletAlertMessage),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentSavingAccessCodesDeleteAlert() {
        let okButton = Alert.Button.destructive(Text(Localization.commonDelete)) { [weak self] in
            self?.setSaveAccessCodes(false)
        }

        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setSaveAccessCodes(true)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsOffSavedAccessCodeAlertMessage),
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
            userWalletRepository.clear()
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

    func updateView() {
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
