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
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var settingsSectionViewModels: [DefaultRowViewModel] = []
    @Published var legalSectionViewModels: [DefaultRowViewModel] = []
    @Published var environmentSetupViewModel: DefaultRowViewModel?

    @Published var cardModel: CardViewModel
    @Published var error: AlertBinder?

    var canCreateBackup: Bool {
        cardModel.canCreateBackup
    }

    var applicationInfoFooter: String? {
        guard let appName = InfoDictionaryUtils.appName.value,
              let version = InfoDictionaryUtils.version.value,
              let bundleVersion = InfoDictionaryUtils.bundleVersion.value else {
            return nil
        }

        return String(
            format: "%@ %@ (%@)",
            arguments: [appName, version, bundleVersion]
        )
    }

    deinit {
        print("DetailsViewModel deinit")
    }

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: DetailsRoutable

    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    init(cardModel: CardViewModel, coordinator: DetailsRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        bind()
        setupView()
    }

    func prepareBackup() {
        Analytics.log(.buttonCreateBackup)
        if let input = cardModel.backupInput {
            self.openOnboarding(with: input)
        }
    }
}

// MARK: - Navigation

extension DetailsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        Analytics.log(.backupScreenOpened)
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        Analytics.log(.buttonSendFeedback)

        guard let emailConfig = cardModel.emailConfig else { return }

        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openMail(with: dataCollector,
                             recipient: emailConfig.recipient,
                             emailType: .appFeedback(subject: emailConfig.subject))
    }

    func openWalletConnect() {
        coordinator.openWalletConnect(with: cardModel)
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)
        coordinator.openScanCardSettings()
    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator.openAppSettings()
    }

    func openSupportChat() {
        Analytics.log(.buttonChat)
        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openSupportChat(cardId: cardModel.cardId,
                                    dataCollector: dataCollector)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(.buttonSocialNetwork)
        coordinator.openInSafari(url: url)
    }

    func openEnvironmentSetup() {
        coordinator.openEnvironmentSetup()
    }
}

// MARK: - Private

extension DetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupSupportSectionModels()
        setupSettingsSectionViewModels()
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
            title: "wallet_connect_title".localized,
            subtitle: "wallet_connect_subtitle".localized,
            action: openWalletConnect
        )
    }

    func setupSupportSectionModels() {
        supportSectionModels = [
            DefaultRowViewModel(title: "details_chat".localized, action: openSupportChat),
            DefaultRowViewModel(title: "details_row_title_send_feedback".localized, action: openMail),
        ]
    }

    func setupSettingsSectionViewModels() {
        var viewModels: [DefaultRowViewModel] = []

        if !cardModel.isMultiWallet {
            viewModels.append(DefaultRowViewModel(
                title: "details_row_title_currency".localized,
                detailsType: .text(selectedCurrencyCode),
                action: coordinator.openCurrencySelection
            ))
        }

        viewModels.append(DefaultRowViewModel(
            title: "details_row_title_card_settings".localized,
            action: openCardSettings
        ))

        // [REDACTED_TODO_COMMENT]
        /*
         viewModels.append(DefaultRowViewModel(
             title: "details_row_title_app_settings".localized,
             action: openAppSettings
         ))
          */

        if canCreateBackup {
            viewModels.append(DefaultRowViewModel(
                title: "details_row_title_create_backup".localized,
                action: prepareBackup
            ))
        }

        settingsSectionViewModels = viewModels
    }

    func setupLegalSectionViewModels() {
        legalSectionViewModels = [
//            DefaultRowViewModel(title: "disclaimer_title".localized, action: coordinator. openDisclaimer),
            DefaultRowViewModel(title: "details_row_title_card_tou".localized) { [weak self] in
                self?.coordinator.openInSafari(url: cardModel.cardTouURL)
            }
        ]
    }

    func setupEnvironmentSetupSection() {
        if AppEnvironment.current.isProduction {
            environmentSetupViewModel = nil
        } else {
            environmentSetupViewModel = DefaultRowViewModel(title: "Environment setup", action: openEnvironmentSetup)
        }
    }
}
