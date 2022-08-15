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
    // MARK: - Dependencies

    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    // MARK: - View State

    @Published var cardModel: CardViewModel
    @Published var error: AlertBinder?

    var canCreateBackup: Bool {
        cardModel.canCreateBackup
    }

    var canTwin: Bool {
        cardModel.canTwin
    }

    var shouldShowWC: Bool {
        cardModel.shouldShowWC
    }

    var cardTouURL: URL? {
        cardModel.cardTouURL
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

    var isMultiWallet: Bool {
        cardModel.isMultiWallet
    }

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: DetailsRoutable

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

    func openCurrencySelection() {
        coordinator.openCurrencySelection()
    }

    func openDisclaimer() {
        coordinator.openDisclaimer()
    }

    func openCardTOU(url: URL) {
        coordinator.openCardTOU(url: url)
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
        coordinator.openSupportChat(cardId: cardModel.cardId)
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
