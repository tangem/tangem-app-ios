//
//  DetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import class TangemSdk.BiometricsUtil
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

@MainActor
final class DetailsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    // MARK: - View State

    @Published var walletConnectRowViewModel: WalletConnectRowViewModel?
    var walletsSectionTypes: [WalletSectionType] {
        var viewModels: [WalletSectionType] = userWalletsViewModels.map { .wallet($0) }
        addOrScanNewUserWalletViewModel.map { viewModel in
            viewModels.append(.addOrScanNewUserWalletButton(viewModel))
        }
        return viewModels
    }

    @Published var getSectionViewModels: [DefaultRowViewModel] = []
    @Published var appSettingsViewModel: DefaultRowViewModel?
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var environmentSetupViewModel: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?
    @Published var chooseSupportTypeDialog: ConfirmationDialogViewModel?
    @Published var scanTroubleshootingDialog: ConfirmationDialogViewModel?

    var userWalletsSectionFooterString: String? {
        guard
            FeatureProvider.isAvailable(.mobileWallet),
            [.mobile, .mixed].contains(UserWalletRepositoryModeHelper.mode)
        else {
            return nil
        }
        return Localization.detailsWalletsSectionDescription
    }

    @Published private var userWalletsViewModels: [SettingsUserWalletRowViewModel] = []
    @Published private var addOrScanNewUserWalletViewModel: DefaultRowViewModel?

    private var isScanning: Bool = false {
        didSet {
            updateAddOrScanNewUserWalletButton()
        }
    }

    private var selectedUserWalletModel: UserWalletModel? {
        userWalletRepository.selectedModel
    }

    var applicationInfoFooter: String? {
        guard
            let appName: String = InfoDictionaryUtils.appName.value(),
            let version: String = InfoDictionaryUtils.version.value(),
            let bundleVersion: String = InfoDictionaryUtils.bundleVersion.value()
        else {
            return nil
        }

        return String(
            format: "%@ %@ (%@)",
            arguments: [appName, version, bundleVersion]
        )
    }

    deinit {
        AppLogger.debug(self)
    }

    // MARK: - Private

    private let signInAnalyticsLogger = SignInAnalyticsLogger()
    private var bag = Set<AnyCancellable>()
    private weak var coordinator: DetailsRoutable?

    init(coordinator: DetailsRoutable) {
        self.coordinator = coordinator

        bind()
        setupView()
    }

    func onAppear() {
        Analytics.log(.settingsScreenOpened)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(event: .buttonSocialNetwork, params: [
            .network: network.name,
        ])
        coordinator?.openSocialNetwork(url: url)
    }
}

// MARK: - Navigation

private extension DetailsViewModel {
    func selectSupport() {
        Analytics.log(.requestSupport, params: [.source: .settings])
        var visaUserWalletModels = [UserWalletModel]()
        var tangemUserWalletModels = [UserWalletModel]()
        userWalletRepository.models.forEach {
            if $0.config.productType == .visa {
                visaUserWalletModels.append($0)
            } else {
                tangemUserWalletModels.append($0)
            }
        }
        let hasVisaCards = !visaUserWalletModels.isEmpty
        let hasTangemCards = !tangemUserWalletModels.isEmpty
        switch (hasVisaCards, hasTangemCards) {
        case (true, true):
            let contactTangemSupportButton = ConfirmationDialogViewModel.Button(title: Localization.commonContactTangemSupport) { [weak self] in
                self?.openTangemSupport(models: tangemUserWalletModels)
            }

            let contactVisaSupportButton = ConfirmationDialogViewModel.Button(title: Localization.commonContactVisaSupport) { [weak self] in
                self?.openVisaSupport(models: visaUserWalletModels)
            }

            chooseSupportTypeDialog = ConfirmationDialogViewModel(
                title: Localization.commonChooseAction,
                buttons: [
                    contactTangemSupportButton,
                    contactVisaSupportButton,
                    ConfirmationDialogViewModel.Button.cancel,
                ]
            )

        case (true, false):
            openVisaSupport(models: visaUserWalletModels)

        case (false, true), (false, false):
            openTangemSupport(models: tangemUserWalletModels)
        }
    }

    func openWalletConnect() {
        Analytics.log(.buttonWalletConnect)
        coordinator?.openWalletConnect(with: selectedUserWalletModel?.config.getDisabledLocalizedReason(for: .walletConnect))
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboardingModal(with: input)
    }

    func openMail(emailConfig: EmailConfig, emailType: EmailType, models: [any UserWalletModel]) {
        let data = models.map {
            DetailsFeedbackData(
                userWalletEmailData: $0.emailData,
                walletModels: AccountsFeatureAwareWalletModelsResolver.walletModels(for: $0)
            )
        }

        let dataCollector = DetailsFeedbackDataCollector(
            data: data
        )

        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: emailType
        )
    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator?.openAppSettings()
    }

    func openBuyWallet() {
        Analytics.log(
            .basicButtonBuy,
            params: [.source: Analytics.BuyWalletSource.settings.parameterValue],
            contextParams: .empty
        )
        coordinator?.openShop()
    }

    func openGetTangemPay() {
        coordinator?.openGetTangemPay()
    }

    func openSupportChat() {
        guard selectedUserWalletModel != nil else {
            return
        }

        Analytics.log(.settingsButtonChat)

        let data = userWalletRepository.models.map {
            DetailsFeedbackData(
                userWalletEmailData: $0.emailData,
                walletModels: AccountsFeatureAwareWalletModelsResolver.walletModels(for: $0)
            )
        }

        let dataCollector = DetailsFeedbackDataCollector(
            data: data
        )

        coordinator?.openSupportChat(input: .init(
            logsComposer: .init(infoProvider: dataCollector)
        ))
    }

    func openTOS() {
        coordinator?.openTOS()
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .settings])
        addOrScanNewUserWallet()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .settings])
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .settings])
        failedCardScanTracker.resetCounter()
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient, emailType: .failedToScanCard)
    }
}

// MARK: - Private

private extension DetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupUserWalletViewModels()
        setupGetSectionViewModels()
        setupAppSettingsViewModel()
        setupSupportSectionModels()
        setupEnvironmentSetupSection()
    }

    func bind() {
        AppSettings.shared.$saveUserWallets
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateAddOrScanNewUserWalletButton()
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                switch event {
                case .inserted, .unlockedWallet, .unlocked:
                    viewModel.setupUserWalletViewModels()
                case .deleted(_, let isEmpty):
                    if !isEmpty {
                        viewModel.setupUserWalletViewModels()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)

        tangemPayAvailabilityRepository.isGetTangemPayFeatureAvailable
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, isAvailable in
                viewModel.setupGetSectionViewModels(
                    shouldShowGetTangemPay: isAvailable
                )
            }
            .store(in: &bag)
    }

    func setupWalletConnectRowViewModel() {
        guard
            let selectedUserWalletModel,
            !selectedUserWalletModel.config.getFeatureAvailability(.walletConnect).isHidden else {
            walletConnectRowViewModel = nil
            return
        }

        walletConnectRowViewModel = WalletConnectRowViewModel(
            title: Localization.walletConnectTitle,
            subtitle: Localization.walletConnectSubtitle,
            action: weakify(self, forFunction: DetailsViewModel.openWalletConnect)
        )
    }

    func setupUserWalletViewModels() {
        userWalletsViewModels = userWalletRepository.models.map { userWallet in
            SettingsUserWalletRowViewModel(userWallet: userWallet) { [weak self] in
                if userWallet.isUserWalletLocked {
                    self?.unlock(userWalletModel: userWallet, onDidUnlock: { userWalletModel in
                        self?.openWalletSettings(userWalletModel: userWalletModel)
                    })
                } else {
                    self?.openWalletSettings(userWalletModel: userWallet)
                }
            }
        }

        addOrScanNewUserWalletViewModel = makeAddOrScanUserWalletViewModel()
    }

    func updateAddOrScanNewUserWalletButton() {
        addOrScanNewUserWalletViewModel = makeAddOrScanUserWalletViewModel()
    }

    func makeAddOrScanUserWalletViewModel() -> DefaultRowViewModel {
        let isSaveUserWallets = AppSettings.shared.saveUserWallets
        return DefaultRowViewModel(
            title: isSaveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton,
            detailsType: isScanning ? .loader : .none,
            action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet)
        )
    }

    func setupGetSectionViewModels(shouldShowGetTangemPay: Bool = false) {
        var models = [
            DefaultRowViewModel(
                title: Localization.detailsBuyWallet,
                action: weakify(self, forFunction: DetailsViewModel.openBuyWallet)
            ),
        ]

        if shouldShowGetTangemPay {
            models.append(
                DefaultRowViewModel(
                    title: Localization.tangempayGetTangemPay,
                    action: weakify(self, forFunction: DetailsViewModel.openGetTangemPay)
                )
            )
        }

        getSectionViewModels = models
    }

    func setupAppSettingsViewModel() {
        appSettingsViewModel = DefaultRowViewModel(
            title: Localization.appSettingsTitle,
            action: weakify(self, forFunction: DetailsViewModel.openAppSettings)
        )
    }

    func setupSupportSectionModels() {
        supportSectionModels = [
            DefaultRowViewModel(
                title: Localization.commonContactSupport,
                action: weakify(self, forFunction: DetailsViewModel.selectSupport)
            ),
            DefaultRowViewModel(
                title: Localization.disclaimerTitle,
                action: weakify(self, forFunction: DetailsViewModel.openTOS)
            ),
        ]
    }

    func setupEnvironmentSetupSection() {
        guard !AppEnvironment.current.isProduction else {
            environmentSetupViewModel = []
            return
        }

        environmentSetupViewModel = [
            DefaultRowViewModel(title: "Environment setup", action: { [weak self] in self?.coordinator?.openEnvironmentSetup() }),
            DefaultRowViewModel(title: "Logs", action: { [weak self] in self?.coordinator?.openLogs() }),
        ]
    }

    func addOrScanNewUserWallet() {
        isScanning = true

        if FeatureProvider.isAvailable(.mobileWallet) {
            Analytics.log(
                .buttonAddWallet,
                params: [.source: .settings],
                contextParams: .empty
            )
        } else {
            Analytics.log(Analytics.CardScanSource.settings.cardScanButtonEvent)
        }

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.isScanning = false

            case .error(let error):
                Analytics.logScanError(error, source: .settings)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .settings)
                viewModel.isScanning = false
                viewModel.alert = error.alertBinder

            case .onboarding(let input, _):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.settings.cardWasScannedParameterValue],
                    contextParams: input.cardInput.getContextParams()
                )

                viewModel.isScanning = false
                viewModel.openOnboarding(with: input)

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .settings])
                viewModel.isScanning = false
                viewModel.openTroubleshooting(onTryAgain: { [weak self] in
                    self?.tryAgain()
                })

            case .success(let cardInfo):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.settings.cardWasScannedParameterValue],
                    contextParams: .custom(cardInfo.analyticsContextData)
                )

                do {
                    let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

                    guard let userWalletId = UserWalletId(config: config) else {
                        throw UserWalletRepositoryError.cantUnlockWallet
                    }

                    if viewModel.userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) {
                        throw UserWalletRepositoryError.duplicateWalletAdded
                    }

                    guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                        walletInfo: .cardWallet(cardInfo),
                        keys: .cardWallet(keys: cardInfo.card.wallets)
                    ) else {
                        throw UserWalletRepositoryError.cantUnlockWallet
                    }

                    let hadSingleMobileWallet = UserWalletRepositoryModeHelper.hasSingleMobileWallet

                    if AppSettings.shared.saveUserWallets {
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)
                    } else {
                        let currentUserWalletId = viewModel.userWalletRepository.selectedModel?.userWalletId
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                        if let currentUserWalletId {
                            viewModel.userWalletRepository.delete(userWalletId: currentUserWalletId)
                        }
                    }

                    if hadSingleMobileWallet {
                        viewModel.logColdWalletAddedAnalytics(cardInfo: cardInfo)
                    }

                    viewModel.isScanning = false
                    viewModel.coordinator?.dismiss()

                } catch {
                    viewModel.isScanning = false
                    viewModel.alert = error.alertBinder
                }
            }
        }
    }
}

// MARK: - Unlocking

private extension DetailsViewModel {
    func unlock(userWalletModel: UserWalletModel, onDidUnlock: @escaping (UserWalletModel) -> Void) {
        runTask(in: self) { viewModel in
            if viewModel.canUnlockWithBiometry() {
                await viewModel.unlockWithBiometry(userWalletModel: userWalletModel, onDidUnlock: onDidUnlock)
            } else {
                await viewModel.unlockWithFallback(userWalletModel: userWalletModel, onDidUnlock: onDidUnlock)
            }
        }
    }

    func canUnlockWithBiometry() -> Bool {
        guard BiometricsUtil.isAvailable else {
            return false
        }
        if FeatureProvider.isAvailable(.mobileWallet) {
            return AppSettings.shared.useBiometricAuthentication
        } else {
            return AppSettings.shared.saveUserWallets
        }
    }

    func unlockWithBiometry(userWalletModel: UserWalletModel, onDidUnlock: @escaping (UserWalletModel) -> Void) async {
        Analytics.log(.mainButtonUnlockAllWithBiometrics)

        do {
            let context = try await UserWalletBiometricsUnlocker().unlock()
            let method = UserWalletRepositoryUnlockMethod.biometricsUserWallet(userWalletId: userWalletModel.userWalletId, context: context)
            let userWalletModel = try await userWalletRepository.unlock(with: method)
            signInAnalyticsLogger.logSignInEvent(signInType: .biometrics, userWalletModel: userWalletModel)
            onDidUnlock(userWalletModel)

        } catch where error.isCancellationError {
            await unlockWithFallback(userWalletModel: userWalletModel, onDidUnlock: onDidUnlock)
        } catch let repositoryError as UserWalletRepositoryError {
            if repositoryError == .biometricsChanged {
                await unlockWithFallback(userWalletModel: userWalletModel, onDidUnlock: onDidUnlock)
            } else {
                alert = repositoryError.alertBinder
            }
        } catch {
            alert = error.alertBinder
        }
    }

    func unlockWithFallback(userWalletModel: UserWalletModel, onDidUnlock: @escaping (UserWalletModel) -> Void) async {
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        let unlockResult = await unlocker.unlock()
        await handleUnlock(
            result: unlockResult,
            userWalletModel: userWalletModel,
            signInType: unlocker.analyticsSignInType,
            onDidUnlock: onDidUnlock
        )
    }

    func handleUnlock(
        result: UserWalletModelUnlockerResult,
        userWalletModel: UserWalletModel,
        signInType: Analytics.SignInType,
        onDidUnlock: @escaping (UserWalletModel) -> Void
    ) async {
        switch result {
        case .error(let error):
            if error.isCancellationError {
                return
            }

            Analytics.logScanError(error, source: .main)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .main)

            alert = error.alertBinder

        case .scanTroubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .main])
            openTroubleshooting(onTryAgain: { [weak self] in
                self?.unlock(userWalletModel: userWalletModel, onDidUnlock: onDidUnlock)
            })

        case .biometrics(let context):
            do {
                let method = UserWalletRepositoryUnlockMethod.biometrics(context)
                let userWalletModel = try await userWalletRepository.unlock(with: method)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)
                onDidUnlock(userWalletModel)

            } catch {
                alert = error.alertBinder
            }

        case .success(let userWalletId, let encryptionKey):
            Analytics.log(
                .cardWasScanned,
                params: [.source: Analytics.CardScanSource.mainUnlock.cardWasScannedParameterValue],
                contextParams: .userWallet(userWalletId)
            )

            do {
                let method = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                let userWalletModel = try await userWalletRepository.unlock(with: method)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)
                onDidUnlock(userWalletModel)

            } catch {
                alert = error.alertBinder
            }

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
        }
    }
}

// MARK: - Support

private extension DetailsViewModel {
    func openTroubleshooting(onTryAgain: @escaping () -> Void) {
        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain, action: onTryAgain)

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.requestSupport()
        }

        scanTroubleshootingDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func openVisaSupport(models: [UserWalletModel]) {
        guard
            let selectedModel = getModelToSendEmail(models: models),
            let emailConfig = selectedModel.emailConfig
        else {
            return
        }

        openMail(emailConfig: emailConfig, emailType: .visaFeedback(subject: .default), models: models)
    }

    func openTangemSupport(models: [UserWalletModel]) {
        guard
            let selectedModel = getModelToSendEmail(models: models),
            let emailConfig = selectedModel.emailConfig
        else {
            return
        }

        openMail(emailConfig: emailConfig, emailType: .appFeedback(subject: emailConfig.subject), models: models)
    }

    func getModelToSendEmail(models: [UserWalletModel]) -> UserWalletModel? {
        let selectedUserWalletModel: UserWalletModel?

        if let selectedModel = self.selectedUserWalletModel,
           models.contains(where: { $0.userWalletId == selectedModel.userWalletId }) {
            selectedUserWalletModel = selectedModel
        } else {
            selectedUserWalletModel = models.first
        }

        return selectedUserWalletModel
    }
}

// MARK: - Analytics

private extension DetailsViewModel {
    func logColdWalletAddedAnalytics(cardInfo: CardInfo) {
        Analytics.log(
            .settingsColdWalletAdded,
            params: [.source: Analytics.ParameterValue.settings],
            analyticsSystems: .all,
            contextParams: .custom(cardInfo.analyticsContextData)
        )
    }
}

// MARK: - Navigation

private extension DetailsViewModel {
    func openWalletSettings(userWalletModel: UserWalletModel) {
        coordinator?.openWalletSettings(options: userWalletModel)
    }
}

extension DetailsViewModel {
    enum WalletSectionType: Identifiable {
        case wallet(SettingsUserWalletRowViewModel)
        case addOrScanNewUserWalletButton(DefaultRowViewModel)

        var id: Int {
            switch self {
            case .wallet(let viewModel):
                return viewModel.id.hashValue
            case .addOrScanNewUserWalletButton(let viewModel):
                return viewModel.id.hashValue
            }
        }
    }
}
