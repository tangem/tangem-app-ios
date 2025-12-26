//
//  NewAppSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder

class NewAppSettingsViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    private let mobileSdk = CommonMobileWalletSdk()

    // MARK: ViewState

    @Published var warningViewModel: DefaultWarningRowViewModel?
    @Published var useBiometricAuthenticationViewModel: DefaultToggleRowViewModel?
    @Published var requireAccessCodesViewModel: DefaultToggleRowViewModel?
    @Published var currencySelectionViewModel: DefaultRowViewModel?
    @Published var sensitiveTextAvailabilityViewModel: DefaultToggleRowViewModel?
    @Published var themeSettingsViewModel: DefaultRowViewModel?

    @Published var useBiometricAuthentication: Bool {
        didSet { AppSettings.shared.useBiometricAuthentication = useBiometricAuthentication }
    }

    @Published var requireAccessCodes: Bool {
        didSet {
            AppSettings.shared.requireAccessCodes = requireAccessCodes
        }
    }

    @Published var alert: AlertBinder?

    var biometricsTitle: String {
        BiometricsUtil.biometryType == .faceID ? Constants.faceIDTitle : Constants.touchIDTitle
    }

    // MARK: Dependencies

    private weak var coordinator: AppSettingsRoutable?

    // MARK: Properties

    private lazy var hasProtectedWallets: Bool = userWalletRepository.models.contains { userWalletModel in
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        return !unlocker.canUnlockAutomatically
    }

    private var bag: Set<AnyCancellable> = []
    private var isBiometryAvailable: Bool = true

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    private var isRequireAccessCodeEnabled: Bool {
        hasProtectedWallets && useBiometricAuthentication
    }

    private var showingBiometryWarning: Bool {
        warningViewModel != nil
    }

    init(coordinator: AppSettingsRoutable) {
        self.coordinator = coordinator

        let useBiometricAuthentication = AppSettings.shared.useBiometricAuthentication
        self.useBiometricAuthentication = useBiometricAuthentication

        requireAccessCodes = !useBiometricAuthentication || AppSettings.shared.requireAccessCodes

        updateView()
        bind()
    }
}

// MARK: - Private

private extension NewAppSettingsViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateView()
            }
            .store(in: &bag)

        $selectedCurrencyCode
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateCurrencySelectionViewModel()
            }
            .store(in: &bag)

        AppSettings.shared.$appTheme
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateThemeSettingsViewModel()
            }
            .store(in: &bag)

        $warningViewModel
            .map {
                $0 != nil
            }
            .removeDuplicates()
            .sink { showingBiometryWarning in
                // Can't do this in onAppear, the view could be updated and the warning displayed after biometry disabled in the settings
                if showingBiometryWarning {
                    Analytics.log(.settingsNoticeEnableBiometrics)
                }
            }
            .store(in: &bag)
    }

    func useBiometricAuthenticationRequestChange(useBiometricAuthentication: Bool) {
        // [REDACTED_TODO_COMMENT]

        guard hasProtectedWallets else {
            presentSetAccessCodeAlert(useBiometricAuthentication: useBiometricAuthentication)
            return
        }

        if useBiometricAuthentication {
            unlockWithBiometry { [weak self] in
                self?.setUseBiometricAuthentication($0)
            }
        } else {
            presentDisableBiometricsAlert()
        }
    }

    func unlockWithBiometry(completion: @escaping (_ success: Bool) -> Void) {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak self] result in
            guard let self else { return }

            if case .failure = result {
                updateView()
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func requireAccessCodesRequestChange(require: Bool) {
        // [REDACTED_TODO_COMMENT]

        presentRequireAccessCodeAlert(require: require)
    }

    func setupView() {
        useBiometricAuthenticationViewModel = DefaultToggleRowViewModel(
            title: biometricsTitle,
            isDisabled: !isBiometryAvailable,
            isOn: useBiometricAuthenticationBinding(),
        )

        if isBiometryAvailable {
            warningViewModel = nil
        } else {
            warningViewModel = DefaultWarningRowViewModel(
                title: Localization.appSettingsWarningTitle,
                subtitle: Localization.appSettingsWarningSubtitle,
                leftView: .icon(Assets.attention)
            ) { [weak self] in
                self?.openBiometrySettings()
            }
        }

        requireAccessCodesViewModel = DefaultToggleRowViewModel(
            title: Localization.appSettingsRequireAccessCode,
            isDisabled: !isRequireAccessCodeEnabled,
            isOn: requireAccessCodesBinding()
        )

        currencySelectionViewModel = DefaultRowViewModel(
            title: Localization.detailsRowTitleCurrency,
            detailsType: .text(selectedCurrencyCode),
            accessibilityIdentifier: AppSettingsAccessibilityIdentifiers.currencyButton,
            action: coordinator?.openCurrencySelection
        )

        sensitiveTextAvailabilityViewModel = DefaultToggleRowViewModel(
            title: Localization.detailsRowTitleFlipToHide,
            isOn: isSensitiveTextAvailability()
        )

        themeSettingsViewModel = DefaultRowViewModel(
            title: Localization.appSettingsThemeSelectorTitle,
            detailsType: .text(AppSettings.shared.appTheme.titleForDetails),
            action: coordinator?.openThemeSelection
        )
    }

    func updateCurrencySelectionViewModel() {
        currencySelectionViewModel?.update(detailsType: .text(selectedCurrencyCode))
    }

    func updateThemeSettingsViewModel() {
        themeSettingsViewModel?.update(detailsType: .text(AppSettings.shared.appTheme.titleForDetails))
    }

    func useBiometricAuthenticationBinding() -> BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.useBiometricAuthentication },
            set: { root, newValue in
                root.useBiometricAuthentication = newValue
                root.useBiometricAuthenticationRequestChange(useBiometricAuthentication: newValue)
            }
        )
    }

    func requireAccessCodesBinding() -> BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.requireAccessCodes },
            set: { root, newValue in
                root.requireAccessCodes = newValue
                root.requireAccessCodesRequestChange(require: newValue)
            }
        )
    }

    func isSensitiveTextAvailability() -> BindingValue<Bool> {
        BindingValue<Bool>(
            get: { AppSettings.shared.isHidingSensitiveAvailable },
            set: { enabled in
                Analytics.log(.hideBalanceChanged, params: [.state: Analytics.ParameterValue.toggleState(for: enabled)])
                AppSettings.shared.isHidingSensitiveAvailable = enabled
            }
        )
    }

    func presentSetAccessCodeAlert(useBiometricAuthentication: Bool) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) { [weak self] in
            self?.setUseBiometricAuthentication(!useBiometricAuthentication)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsAccessCodeWarning),
            dismissButton: okButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentDisableBiometricsAlert() {
        let okButton = Alert.Button.destructive(Text(Localization.commonDisable)) { [weak self] in
            self?.setUseBiometricAuthentication(false)
        }
        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setUseBiometricAuthentication(true)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsOffBiometricsAlertMessage(biometricsTitle)),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentRequireAccessCodeAlert(require: Bool) {
        let okButton = if require {
            Alert.Button.destructive(Text(Localization.commonEnable)) { [weak self] in
                self?.setRequireAccessCodes(require)
            }
        } else {
            Alert.Button.default(Text(Localization.commonOk)) { [weak self] in
                self?.setRequireAccessCodes(require)
            }
        }

        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setRequireAccessCodes(!require)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: require
                ? Text(Localization.appSettingsOnRequireAccessCodeAlertMessage)
                : Text(Localization.appSettingsOffRequireAccessCodeAlertMessage),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func setUseBiometricAuthentication(_ useBiometricAuthentication: Bool) {
        userWalletRepository.onBiometricsChanged(enabled: useBiometricAuthentication)
        self.useBiometricAuthentication = useBiometricAuthentication

        // If saved wallets is turn off we should delete access codes too
        if !useBiometricAuthentication {
            requireAccessCodes = true
        }

        updateView()
    }

    func setRequireAccessCodes(_ requireAccessCodes: Bool) {
        if requireAccessCodes {
            let accessCodeRepository = AccessCodeRepository()
            accessCodeRepository.clear()

            clearBiometricsForMobileWallets()

            self.requireAccessCodes = true
        } else {
            // If useBiometricAuthentication already on, just update settings
            if useBiometricAuthentication {
                self.requireAccessCodes = requireAccessCodes
            } else {
                // Otherwise useBiometricAuthentication should be on after biometry authorization
                unlockWithBiometry { [weak self] success in
                    self?.setUseBiometricAuthentication(success)
                    self?.requireAccessCodes = false
                }
            }
        }
    }

    func updateView() {
        isBiometryAvailable = BiometricsUtil.isAvailable
        setupView()
    }

    func clearBiometricsForMobileWallets() {
        mobileSdk.clearBiometrics(walletIDs: userWalletRepository.models.map { $0.userWalletId })
    }
}

// MARK: - Navigation

extension NewAppSettingsViewModel {
    func openTokenSynchronization() {
        coordinator?.openTokenSynchronization()
    }

    func openResetSavedCards() {
        coordinator?.openResetSavedCards()
    }

    func openBiometrySettings() {
        Analytics.log(.buttonEnableBiometricAuthentication)
        coordinator?.openAppSettings()
    }
}

extension NewAppSettingsViewModel {
    enum Constants {
        static let faceIDTitle = "Face ID"
        static let touchIDTitle = "Touch ID"
    }
}
