//
//  CardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class CardSettingsViewModel: ObservableObject {
    @Injected(\.onboardingStepsSetupService) private var onboardingStepsSetupService: OnboardingStepsSetupService

    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool = false
    @Published var isChangeAccessCodeVisible: Bool = false
    @Published var securityModeTitle: String
    @Published var alert: AlertBinder?
    @Published var isChangeAccessCodeLoading: Bool = false

    var cardId: String {
        let cardId = cardModel.cardInfo.card.cardId
        if cardModel.isTwinCard {
            return AppTwinCardIdFormatter.format(
                cid: cardId,
                cardNumber: cardModel.cardInfo.twinCardInfo?.series.number
            )
        }

        return AppCardIdFormatter(cid: cardId).formatted()
    }

    var cardIssuer: String {
        cardModel.cardInfo.card.issuer.name
    }

    var cardSignedHashes: String? {
        guard cardModel.hasWallet, !cardModel.isTwinCard else {
            return nil
        }

        return "\(cardModel.cardInfo.card.walletSignedHashes)"
    }

    // MARK: Dependecies

    private unowned let coordinator: CardSettingsRoutable
    private let cardModel: CardViewModel

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true

    init(
        cardModel: CardViewModel,
        coordinator: CardSettingsRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecurityOption.title
        hasSingleSecurityMode = cardModel.availableSecurityOptions.count <= 1
        isChangeAccessCodeVisible = cardModel.currentSecurityOption == .accessCode

        bind()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        cardModel.$currentSecurityOption
            .map { $0.title }
            .weakAssign(to: \.securityModeTitle, on: self)
            .store(in: &bag)
    }

    func prepareTwinOnboarding() {
        onboardingStepsSetupService.twinRecreationSteps(for: cardModel.cardInfo)
            .sink { completion in
                guard case let .failure(error) = completion else {
                    return
                }

                Analytics.log(error: error)
                print("Failed to load image for new card")
                self.alert = error.alertBinder
            } receiveValue: { [weak self] steps in
                guard let self = self else { return }

                let input = OnboardingInput(
                    steps: steps,
                    cardInput: .cardModel(self.cardModel),
                    welcomeStep: nil,
                    currentStepIndex: 0,
                    isStandalone: true
                )

                self.coordinator.openOnboarding(with: input)
            }
            .store(in: &bag)
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        isChangeAccessCodeLoading = true
        cardModel.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
            }
        }
    }

    func openSecurityMode() {
        coordinator.openSecurityMode(cardModel: cardModel)
    }

    func openResetCard() {
        if cardModel.isTwinCard {
            prepareTwinOnboarding()
        } else {
            coordinator.openResetCardToFactoryWarning { [weak self] in
                self?.cardModel.resetToFactory { [weak self] result in
                    switch result {
                    case .success:
                        self?.coordinator.openOnboarding()
                    case let .failure(error):
                        print("ResetCardToFactoryWarning error", error)
                    }
                }
            }
        }
    }
}
