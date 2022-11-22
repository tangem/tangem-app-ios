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

    var cardTouURL: URL {
        cardModel.cardTouURL
    }

    var canSendMail: Bool {
        cardModel.emailConfig != nil
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

    func openCurrencySelection() {
        coordinator.openCurrencySelection()
    }

    func openDisclaimer() {
        coordinator.openDisclaimer(at: cardModel.cardTouURL)
    }

    func openCardSettings() {
        guard let userWalletId = cardModel.userWalletId else {
            // This shouldn't be the case, because currently user can't reach this screen
            // with card that doesn't have a wallet.
            return
        }

        Analytics.log(.buttonCardSettings)
        coordinator.openScanCardSettings(with: userWalletId)
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
