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
import TangemSdk
import BlockchainSdk

class DetailsViewModel: ObservableObject {
    // MARK: - View State

    @Published var walletConnectRowViewModel: WalletConnectRowViewModel?
    @Published var commonSectionViewModels: [DefaultRowViewModel] = []
    @Published var settingsSectionViewModels: [DefaultRowViewModel] = []
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var legalSectionViewModel: DefaultRowViewModel?
    @Published var environmentSetupViewModel: DefaultRowViewModel?

    @Published var cardModel: CardViewModel
    @Published var alert: AlertBinder?

    var canCreateBackup: Bool {
        cardModel.canCreateBackup
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
    private unowned let coordinator: DetailsRoutable

    init(cardModel: CardViewModel, coordinator: DetailsRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        bind()
        setupView()
    }

    func prepareBackup() {
        Analytics.log(.buttonCreateBackup)
        if let input = cardModel.backupInput {
            openOnboarding(with: input)
        }
    }

    func didFinishOnboarding() {
        setupView()
    }
}

// MARK: - Navigation

extension DetailsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        Analytics.log(.buttonSendFeedback)

        guard let emailConfig = cardModel.emailConfig else { return }

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: cardModel.walletModelsManager.walletModels,
            userWalletEmailData: cardModel.emailData
        )

        coordinator.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }

    func openWalletConnect() {
        Analytics.log(.buttonWalletConnect)
        coordinator.openWalletConnect(with: cardModel.getDisabledLocalizedReason(for: .walletConnect))
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)
        coordinator.openScanCardSettings(with: cardModel.userWalletId.value, sdk: cardModel.makeTangemSdk()) // [REDACTED_TODO_COMMENT]
    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator.openAppSettings()
    }

    func openSupportChat() {
        Analytics.log(.settingsButtonChat)

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: cardModel.walletModelsManager.walletModels,
            userWalletEmailData: cardModel.emailData
        )

        coordinator.openSupportChat(input: .init(
            logsComposer: .init(infoProvider: dataCollector)
        ))
    }

    func openDisclaimer() {
        coordinator.openDisclaimer(at: cardModel.cardDisclaimer.url)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(event: .buttonSocialNetwork, params: [
            .network: network.name,
        ])
        coordinator.openInSafari(url: url)
    }

    func openEnvironmentSetup() {
        coordinator.openEnvironmentSetup()
    }

    func openReferral() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let input = ReferralInputModel(
            userWalletId: cardModel.userWalletId.value,
            supportedBlockchains: cardModel.config.supportedBlockchains,
            userTokensManager: cardModel.userTokensManager
        )

        coordinator.openReferral(input: input)
    }

    func onAppear() {
        Analytics.log(.settingsScreenOpened)
    }
}

// MARK: - Private

extension DetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupCommonSectionViewModels()
        setupSettingsSectionViewModels()
        setupSupportSectionModels()
        setupLegalSectionViewModels()
        setupEnvironmentSetupSection()
    }

    func bind() {
        cardModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func setupWalletConnectRowViewModel() {
        guard cardModel.shouldShowWC else {
            walletConnectRowViewModel = nil
            return
        }

        walletConnectRowViewModel = WalletConnectRowViewModel(
            title: Localization.walletConnectTitle,
            subtitle: Localization.walletConnectSubtitle,
            action: openWalletConnect
        )
    }

    func setupSupportSectionModels() {
        supportSectionModels = [
            DefaultRowViewModel(title: Localization.detailsChat, action: openSupportChat),
        ]

        if cardModel.canParticipateInReferralProgram {
            supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsReferralTitle, action: openReferral))
        }

        if cardModel.emailConfig != nil {
            supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsRowTitleSendFeedback, action: openMail))
        }
    }

    func setupSettingsSectionViewModels() {
        var viewModels: [DefaultRowViewModel] = []

        viewModels.append(DefaultRowViewModel(
            title: Localization.cardSettingsTitle,
            action: openCardSettings
        ))

        // [REDACTED_TODO_COMMENT]

        viewModels.append(DefaultRowViewModel(
            title: Localization.appSettingsTitle,
            action: openAppSettings
        ))

        settingsSectionViewModels = viewModels
    }

    func setupLegalSectionViewModels() {
        legalSectionViewModel = DefaultRowViewModel(
            title: Localization.disclaimerTitle,
            action: openDisclaimer
        )
    }

    func setupEnvironmentSetupSection() {
        if !AppEnvironment.current.isProduction {
            environmentSetupViewModel = DefaultRowViewModel(title: "Environment setup", action: openEnvironmentSetup)
        }
    }

    func setupCommonSectionViewModels() {
        var viewModels: [DefaultRowViewModel] = []

        if canCreateBackup {
            viewModels.append(DefaultRowViewModel(
                title: Localization.detailsRowTitleCreateBackup,
                action: prepareBackup
            ))
        }

        commonSectionViewModels = viewModels
    }
}
