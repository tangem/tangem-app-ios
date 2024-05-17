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

    var walletsSectionTypes: [WalletSectionType] {
        var viewModels: [WalletSectionType] = detailsUserWalletRowViewModels.map { .wallet($0) }
        addOrScanNewUserWalletViewModel.map { viewModel in
            viewModels.append(.addOrScanNewUserWalletButton(viewModel))
        }

        return viewModels
    }

    @Published var settingsSectionViewModels: [DefaultRowViewModel] = []
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var environmentSetupViewModel: DefaultRowViewModel?
    @Published var alert: AlertBinder?
    @Published var showTroubleshootingView: Bool = false

    @Published private var detailsUserWalletRowViewModels: [DetailsUserWalletRowViewModel] = []
    @Published private var addOrScanNewUserWalletViewModel: DefaultRowViewModel?

    private var isScanning: Bool = false {
        didSet {
            updateAddOrScanNewUserWalletButton()
        }
    }

//    var canCreateBackup: Bool {
//        !userWalletModel.config.getFeatureAvailability(.backup).isHidden
//    }

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

//    func prepareBackup() {
//        Analytics.log(.buttonCreateBackup)
//        if let backupInput = userWalletModel.backupInput {
//            openOnboarding(with: backupInput)
//        }
//    }
}

// MARK: - Navigation

extension DetailsViewModel {
//    func openOnboarding(with input: OnboardingInput) {
//        coordinator?.openOnboardingModal(with: input)
//    }

    func openMail() {
        Analytics.log(.requestSupport, params: [.source: .settings])
        // [REDACTED_TODO_COMMENT]
        /*
                guard let emailConfig = userWalletModel.config.emailConfig else { return }

                let dataCollector = DetailsFeedbackDataCollector(
                    walletModels: userWalletModel.walletModelsManager.walletModels,
                    userWalletEmailData: userWalletModel.emailData
                )

                coordinator?.openMail(
                    with: dataCollector,
                    recipient: emailConfig.recipient,
                    emailType: .appFeedback(subject: emailConfig.subject)
                )
         */
    }

//    func openWalletConnect() {
//        Analytics.log(.buttonWalletConnect)
//        coordinator?.openWalletConnect(with: userWalletModel.config.getDisabledLocalizedReason(for: .walletConnect))
//    }

//    func openCardSettings() {
//        Analytics.log(.buttonCardSettings)
//
//        let scanParameters = CardScannerParameters(
//            shouldAskForAccessCodes: true,
//            performDerivations: false,
//            sessionFilter: userWalletModel.config.cardSessionFilter
//        )
//
//        let scanner = CardScannerFactory().makeScanner(
//            with: userWalletModel.config.makeTangemSdk(),
//            parameters: scanParameters
//        )
//
//        coordinator?.openScanCardSettings(with: scanner)
//    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator?.openAppSettings()
    }

//    func openSupportChat() {
//        Analytics.log(.settingsButtonChat)
//
//        let dataCollector = DetailsFeedbackDataCollector(
//            walletModels: userWalletModel.walletModelsManager.walletModels,
//            userWalletEmailData: userWalletModel.emailData
//        )
//
//        coordinator?.openSupportChat(input: .init(
//            logsComposer: .init(infoProvider: dataCollector)
//        ))
//    }

//    func openDisclaimer() {
//        coordinator?.openDisclaimer(at: userWalletModel.config.tou.url)
//    }

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

//    func openReferral() {
//        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
//            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
//            return
//        }
//
//        let input = ReferralInputModel(
//            userWalletId: userWalletModel.userWalletId.value,
//            supportedBlockchains: userWalletModel.config.supportedBlockchains,
//            userTokensManager: userWalletModel.userTokensManager
//        )
//
//        coordinator?.openReferral(input: input)
//    }

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
//        setupWalletConnectRowViewModel()
        setupUserWalletViewModels()
//        setupCommonSectionViewModels()
        setupSettingsSectionViewModels()
        setupSupportSectionModels()
//        setupLegalSectionViewModels()
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

//        userWalletRepository.eventProvider
//            .withWeakCaptureOf(self)
//            .sink { viewModel, event in
//                switch event {
//                case .scan:
//                    break
//                default:
//                    viewModel.setupUserWalletViewModels()
//                }
//            }
//            .store(in: &bag)
    }

//    func setupWalletConnectRowViewModel() {
//        guard !userWalletModel.config.getFeatureAvailability(.walletConnect).isHidden else {
//            walletConnectRowViewModel = nil
//            return
//        }
//
//        walletConnectRowViewModel = WalletConnectRowViewModel(
//            title: Localization.walletConnectTitle,
//            subtitle: Localization.walletConnectSubtitle,
//            action: weakify(self, forFunction: DetailsViewModel.openWalletConnect)
//        )
//    }

    func setupSupportSectionModels() {
//        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
//            supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsReferralTitle, action: weakify(self, forFunction: DetailsViewModel.openReferral)))
//        }

        // [REDACTED_TODO_COMMENT]
//        if userWalletModel.config.emailConfig != nil {
        supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsRowTitleContactToSupport, action: weakify(self, forFunction: DetailsViewModel.openMail)))
//        }
    }

    func setupSettingsSectionViewModels() {
        settingsSectionViewModels = [
            DefaultRowViewModel(
                title: Localization.appSettingsTitle,
                action: weakify(self, forFunction: DetailsViewModel.openAppSettings)
            ),
        ]
    }

//    func setupLegalSectionViewModels() {
//        legalSectionViewModel = DefaultRowViewModel(
//            title: Localization.disclaimerTitle,
//            action: weakify(self, forFunction: DetailsViewModel.openDisclaimer)
//        )
//    }

    func setupEnvironmentSetupSection() {
        if AppEnvironment.current.isProduction {
            environmentSetupViewModel = DefaultRowViewModel(title: "Environment setup", action: weakify(self, forFunction: DetailsViewModel.openEnvironmentSetup))
        }
    }

    func setupUserWalletViewModels() {
        detailsUserWalletRowViewModels = userWalletRepository.models.map { userWallet in
            .init(userWallet: userWallet) { [weak self] in
                self?.coordinator?.openWalletsDetails(options: userWallet)
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

//    func setupCommonSectionViewModels() {
//        var viewModels: [DefaultRowViewModel] = []
//
//        viewModels.append(DefaultRowViewModel(
//            title: AppSettings.shared.saveUserWallets ? Localization.userWalletListAddButton : Localization.scanCardSettingsButton,
//            detailsType: isScanning ? .loader : .none,
//            action: isScanning ? nil : weakify(self, forFunction: DetailsViewModel.addOrScanNewUserWallet)
//        ))
//
//        if canCreateBackup {
//            viewModels.append(DefaultRowViewModel(
//                title: Localization.detailsRowTitleCreateBackup,
//                action: weakify(self, forFunction: DetailsViewModel.prepareBackup)
//            ))
//        }
//
//        commonSectionViewModels = viewModels
//    }

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
        case wallet(DetailsUserWalletRowViewModel)
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
