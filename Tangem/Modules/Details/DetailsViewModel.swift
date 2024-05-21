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

        return viewModels
    }

    @Published var appSettingsViewModel: DefaultRowViewModel?
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var environmentSetupViewModel: DefaultRowViewModel?
    @Published var alert: AlertBinder?
    @Published var showTroubleshootingView: Bool = false

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
        AppLog.shared.debug("DetailsViewModel deinit")
    }

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private weak var coordinator: DetailsRoutable?

    init(coordinator: DetailsRoutable) {
        self.coordinator = coordinator

        bind()
        setupView()
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

    func openMail() {
        Analytics.log(.requestSupport, params: [.source: .settings])
        guard let selectedUserWalletModel,
              let emailConfig = selectedUserWalletModel.config.emailConfig else {
            return
        }

        // Collect data from the all wallets
        let walletModels = userWalletRepository.models.flatMap { $0.walletModelsManager.walletModels }
        let emailData = userWalletRepository.models.flatMap { $0.emailData }
        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: walletModels,
            userWalletEmailData: emailData
        )

        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator?.openAppSettings()
    }

    func openSupportChat() {
        guard let selectedUserWalletModel else {
            return
        }

        Analytics.log(.settingsButtonChat)

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: selectedUserWalletModel.walletModelsManager.walletModels,
            userWalletEmailData: selectedUserWalletModel.emailData
        )

        coordinator?.openSupportChat(input: .init(
            logsComposer: .init(infoProvider: dataCollector)
        ))
    }

    func openDisclaimer() {
        coordinator?.openDisclaimer(at: selectedUserWalletModel!.config.tou.url)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(event: .buttonSocialNetwork, params: [
            .network: network.name,
        ])
        coordinator?.openInSafari(url: url)
    }

    func openEnvironmentSetup() {
        coordinator?.openEnvironmentSetup()
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

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .settings])
        failedCardScanTracker.resetCounter()
        coordinator?.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient, emailType: .failedToScanCard)
    }
}

// MARK: - Private

private extension DetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupUserWalletViewModels()
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
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                switch event {
                case .scan:
                    break
                default:
                    viewModel.setupUserWalletViewModels()
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

        addOrScanNewUserWalletViewModel = DefaultRowViewModel(
            title: AppSettings.shared.saveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton,
            detailsType: isScanning ? .loader : .none,
            action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet)
        )
    }

    func updateAddOrScanNewUserWalletButton() {
        addOrScanNewUserWalletViewModel?.update(title: AppSettings.shared.saveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton)
        addOrScanNewUserWalletViewModel?.update(detailsType: isScanning ? .loader : .none)
        addOrScanNewUserWalletViewModel?.update(action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet))
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
                action: weakify(self, forFunction: DetailsViewModel.openMail)
            ),
            DefaultRowViewModel(
                title: Localization.disclaimerTitle,
                action: weakify(self, forFunction: DetailsViewModel.openDisclaimer)
            ),
        ]
    }

    func setupEnvironmentSetupSection() {
        if !AppEnvironment.current.isProduction {
            environmentSetupViewModel = DefaultRowViewModel(
                title: "Environment setup",
                action: weakify(self, forFunction: DetailsViewModel.openEnvironmentSetup)
            )
        }
    }

    func addOrScanNewUserWallet() {
        Analytics.beginLoggingCardScan(source: .settings)
        isScanning = true

        userWalletRepository.addOrScan(scanner: CardScannerFactory().makeDefaultScanner()) { [weak self] result in
            guard let self else {
                return
            }

            isScanning = false

            switch result {
            case .none:
                break
            case .troubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .settings])
                showTroubleshootingView = true
            case .onboarding(let input):
                coordinator?.openOnboardingModal(with: input)
            case .error(let error):
                if let userWalletRepositoryError = error as? UserWalletRepositoryError {
                    alert = userWalletRepositoryError.alertBinder
                } else {
                    alert = error.alertBinder
                }
            case .success, .partial:
                coordinator?.dismiss()
            }
        }
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
