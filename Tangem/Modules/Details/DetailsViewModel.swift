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
    private let dataCollector: DetailsFeedbackDataCollector


    // MARK: - View State

    @Published var cardModel: CardViewModel
    @Published var error: AlertBinder?

    var canCreateBackup: Bool {
        cardModel.config.hasFeature(.backup)
    }

    var canTwin: Bool {
        cardModel.config.hasFeature(.twinning)
    }

    var shouldShowWC: Bool {
        return !cardModel.config.getFeatureAvailability(.walletConnect).isHidden
    }

    var cardTouURL: URL? {
        cardModel.config.touURL
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
        cardModel.config.hasFeature(.manageTokens)
    }

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: DetailsRoutable

    init(cardModel: CardViewModel, coordinator: DetailsRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator
        dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel)

        bind()
    }

    func prepareBackup() {
        if let backupSteps = cardModel.config.backupSteps {
            let input = OnboardingInput(steps: backupSteps,
                                        cardInput: .cardModel(self.cardModel),
                                        welcomeStep: nil,
                                        currentStepIndex: 0,
                                        isStandalone: true)

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
        coordinator.openMail(with: dataCollector,
                             recipient: cardModel.config.emailConfig.subject,
                             emailType: .appFeedback(subject: cardModel.config.emailConfig.subject))
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
        coordinator.openScanCardSettings()
    }

    func openAppSettings() {
        coordinator.openAppSettings()
    }

    func openSupportChat() {
        coordinator.openSupportChat(cardId: cardModel.cardInfo.card.cardId)
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
