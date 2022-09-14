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

    @Published var cardModel: CardViewModel
    @Published var error: AlertBinder?

    var walletConnectRowViewModel: WalletConnectRowViewModel? {
        guard cardModel.shouldShowWC else {
            return nil
        }

        return WalletConnectRowViewModel(
            title: "wallet_connect_title".localized,
            subtitle: "wallet_connect_subtitle".localized,
            action: openWalletConnect
        )
    }

    var supportSectionModels: [DefaultRowViewModel] {
        [
            DefaultRowViewModel(title: "details_chat".localized, action: openSupportChat),
            DefaultRowViewModel(title: "details_row_title_send_feedback".localized, action: openMail),
        ]
    }

    var settingsSectionViewModels: [DefaultRowViewModel] {
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

        if canCreateBackup {
            viewModels.append(DefaultRowViewModel(
                title: "details_row_title_create_backup".localized,
                action: prepareBackup
            ))
        }

        return viewModels
    }

    var legalSectionViewModels: [DefaultRowViewModel] {
        var viewModels: [DefaultRowViewModel] = [
            DefaultRowViewModel(title: "disclaimer_title".localized, action: coordinator.openDisclaimer),
        ]

        if let url = cardModel.cardTouURL {
            viewModels.append(DefaultRowViewModel(title: "details_row_title_card_tou".localized) { [weak self] in
                self?.coordinator.openCardTOU(url: url)
            })
        }

        return viewModels
    }

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
    }

    func prepareBackup() {
        Analytics.log(.backupTapped)
        if let input = cardModel.backupInput {
            self.openOnboarding(with: input)
        }
    }
}

// MARK: - Navigation

extension DetailsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openMail(with: dataCollector,
                             recipient: cardModel.emailConfig.subject,
                             emailType: .appFeedback(subject: cardModel.emailConfig.subject))
    }

    func openWalletConnect() {
        coordinator.openWalletConnect(with: cardModel)
    }

    func openCardSettings() {
        Analytics.log(.cardSettingsTapped)
        coordinator.openScanCardSettings()
    }

    func openAppSettings() {
        Analytics.log(.appSettingsTapped)
        coordinator.openAppSettings()
    }

    func openSupportChat() {
        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openSupportChat(cardId: cardModel.cardId,
                                    dataCollector: dataCollector)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        coordinator.openInSafari(url: url)
    }
}

// MARK: - Private

private extension DetailsViewModel {
    func bind() {
        cardModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

}
