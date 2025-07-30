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
import TangemUIUtils

class DetailsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    // MARK: - View State

    @Published var walletConnectRowViewModel: WalletConnectRowViewModel?
    var walletsSectionTypes: [WalletSectionType] {
        var viewModels: [WalletSectionType] = userWalletsViewModels.map { .wallet($0) }
        addOrScanNewUserWalletViewModel.map { viewModel in
            viewModels.append(.addOrScanNewUserWalletButton(viewModel))
        }
        addNewUserWalletViewModel.map { viewModel in
            viewModels.append(.addNewUserWalletButton(viewModel))
        }

        return viewModels
    }

    @Published var buyWalletViewModel: DefaultRowViewModel?
    @Published var appSettingsViewModel: DefaultRowViewModel?
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var environmentSetupViewModel: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    @Published private var userWalletsViewModels: [SettingsUserWalletRowViewModel] = []
    @Published private var addOrScanNewUserWalletViewModel: DefaultRowViewModel?
    @Published private var addNewUserWalletViewModel: DefaultRowViewModel?

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

    private var bag = Set<AnyCancellable>()
    private weak var coordinator: DetailsRoutable?

    init(coordinator: DetailsRoutable) {
        self.coordinator = coordinator

        bind()
        setupView()
    }

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
            let sheet = ActionSheet(
                title: Text(Localization.commonChooseAction),
                buttons: [
                    .default(Text(Localization.commonContactTangemSupport), action: { [weak self] in
                        self?.openTangemSupport(models: tangemUserWalletModels)
                    }),
                    .default(Text(Localization.commonContactVisaSupport), action: { [weak self] in
                        self?.openVisaSupport(models: visaUserWalletModels)
                    }),
                    .cancel(Text(Localization.commonCancel)),
                ]
            )

            actionSheet = ActionSheetBinder(sheet: sheet)
        case (true, false):
            openVisaSupport(models: visaUserWalletModels)
        case (false, true), (false, false):
            openTangemSupport(models: tangemUserWalletModels)
        }
    }
}

// MARK: - Navigation

extension DetailsViewModel {
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
                walletModels: $0.walletModelsManager.walletModels
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
        Analytics.log(.shopScreenOpened)
        coordinator?.openShop()
    }

    func openSupportChat() {
        guard selectedUserWalletModel != nil else {
            return
        }

        Analytics.log(.settingsButtonChat)

        let data = userWalletRepository.models.map {
            DetailsFeedbackData(
                userWalletEmailData: $0.emailData,
                walletModels: $0.walletModelsManager.walletModels
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

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(event: .buttonSocialNetwork, params: [
            .network: network.name,
        ])
        coordinator?.openSocialNetwork(url: url)
    }

    func onAppear() {
        Analytics.log(.settingsScreenOpened)
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .settings])
        addOrScanNewUserWallet()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .settings])
        coordinator?.openScanCardManual()
    }

    func openAddNewUserWallet() {
        let sheet = ActionSheet(
            title: Text(Localization.userWalletListAddButton),
            buttons: [
                .default(
                    Text(Localization.homeButtonCreateNewWallet),
                    action: weakify(self, forFunction: DetailsViewModel.openCreateWallet)
                ),
                .default(
                    Text(Localization.homeButtonAddExistingWallet),
                    action: weakify(self, forFunction: DetailsViewModel.openImportWallet)
                ),
                .default(
                    Text(Localization.detailsBuyWallet),
                    action: weakify(self, forFunction: DetailsViewModel.openBuyWallet)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openCreateWallet() {
        coordinator?.openCreateWallet()
    }

    func openImportWallet() {
        coordinator?.openImportWallet()
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
        setupBuyWalletViewModel()
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
                case .inserted, .deleted:
                    viewModel.setupUserWalletViewModels()
                default:
                    break
                }
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
            .init(userWallet: userWallet) { [weak self] in
                self?.coordinator?.openWalletSettings(options: userWallet)
            }
        }

        if FeatureProvider.isAvailable(.hotWallet) {
            addNewUserWalletViewModel = DefaultRowViewModel(
                title: Localization.userWalletListAddButton,
                action: weakify(self, forFunction: DetailsViewModel.openAddNewUserWallet)
            )
        } else {
            addOrScanNewUserWalletViewModel = DefaultRowViewModel(
                title: AppSettings.shared.saveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton,
                detailsType: isScanning ? .loader : .none,
                action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet)
            )
        }
    }

    func updateAddOrScanNewUserWalletButton() {
        addOrScanNewUserWalletViewModel?.update(title: AppSettings.shared.saveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton)
        addOrScanNewUserWalletViewModel?.update(detailsType: isScanning ? .loader : .none)
        addOrScanNewUserWalletViewModel?.update(action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet))
    }

    func setupBuyWalletViewModel() {
        buyWalletViewModel = DefaultRowViewModel(
            title: Localization.detailsBuyWallet,
            action: weakify(self, forFunction: DetailsViewModel.openBuyWallet)
        )
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
                title: Localization.detailsRowTitleContactToSupport,
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
        Analytics.beginLoggingCardScan(source: .settings)
        isScanning = true

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                await runOnMain {
                    viewModel.isScanning = false
                }

            case .error(let error):
                Analytics.logScanError(error, source: .settings)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .settings)

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.alert = error.alertBinder
                }

            case .onboarding(let input):
                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openOnboarding(with: input)
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .settings])

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                do {
                    guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                        walletInfo: .cardWallet(cardInfo),
                        keys: .cardWallet(keys: cardInfo.card.wallets)
                    ) else {
                        await runOnMain {
                            viewModel.coordinator?.dismiss()
                        }
                        return
                    }

                    if await AppSettings.shared.saveUserWallets {
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)
                    } else {
                        let currentUserWalletId = viewModel.userWalletRepository.selectedModel?.userWalletId
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                        if let currentUserWalletId {
                            viewModel.userWalletRepository.delete(userWalletId: currentUserWalletId)
                        }
                    }

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.coordinator?.dismiss()
                    }

                } catch {
                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.alert = error.alertBinder
                    }
                }
            }
        }
    }
}

// MARK: - Support

private extension DetailsViewModel {
    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: DetailsViewModel.tryAgain)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: DetailsViewModel.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: DetailsViewModel.requestSupport)),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
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

extension DetailsViewModel {
    enum WalletSectionType: Identifiable {
        case wallet(SettingsUserWalletRowViewModel)
        case addOrScanNewUserWalletButton(DefaultRowViewModel)
        case addNewUserWalletButton(DefaultRowViewModel)

        var id: Int {
            switch self {
            case .wallet(let viewModel):
                return viewModel.id.hashValue
            case .addOrScanNewUserWalletButton(let viewModel):
                return viewModel.id.hashValue
            case .addNewUserWalletButton(let viewModel):
                return viewModel.id.hashValue
            }
        }
    }
}
