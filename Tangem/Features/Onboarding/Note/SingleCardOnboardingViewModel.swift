//
//  SingleCardOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemSdk
import Combine
import BlockchainSdk
import TangemUI

class SingleCardOnboardingViewModel: OnboardingViewModel<SingleCardOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Published var isCardScanned: Bool = true

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var mainButtonSettings: MainButton.Settings? {
        switch currentStep {
        case .pushNotifications, .createWallet, .success:
            return nil
        default:
            return super.mainButtonSettings
        }
    }

    override var supplementButtonStyle: MainButton.Style {
        switch currentStep {
        case .createWallet, .success:
            return .primary
        default:
            return super.supplementButtonStyle
        }
    }

    override var supplementButtonIcon: MainButton.Icon? {
        if let icon = currentStep.supplementButtonIcon {
            return .trailing(icon)
        }

        return nil
    }

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .pushNotifications, .addTokens:
            return true
        default:
            return false
        }
    }

    override var isSupportButtonVisible: Bool {
        switch currentStep {
        case .success:
            return false
        default:
            return true
        }
    }

    var infoText: String? {
        currentStep.infoText
    }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        super.init(input: input, coordinator: coordinator)

        if case .singleWallet(let steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }

        bind()
    }

    // MARK: Functions

    private func bind() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let self,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .success:
                    fireConfetti()
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    func onAppear() {
        playInitialAnim()
    }

    override func backButtonAction() {
        alert = AlertBuilder.makeExitAlert { [weak self] in
            self?.closeOnboarding()
        }
    }

    override func mainButtonAction() {}

    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            createWallet()
        case .success:
            goToNextStep()
        default:
            break
        }
    }

    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        switch currentStep {
        case .saveUserWallet:
            mainCardSettings = .zero
            supplementCardSettings = .zero
        default:
            mainCardSettings = .init(
                targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(
                    for: currentStep,
                    containerSize: containerSize,
                    animated: animated
                ),
                intermediateSettings: nil
            )
            supplementCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
        }
    }

    private func createWallet() {
        guard let cardInitializer = input.cardInitializer else { return }

        AppSettings.shared.cardsStartedActivation.insert(input.primaryCardId)
        logAnalytics(.buttonCreateWallet)
        isMainButtonBusy = true

        cardInitializer.initializeCard(mnemonic: nil, passphrase: nil) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let result):
                initializeUserWallet(from: result)

                var params = [Analytics.ParameterKey.creationType: Analytics.ParameterValue.walletCreationTypePrivateKey.rawValue]
                params.enrich(with: ReferralAnalyticsHelper().getReferralParams())
                logAnalytics(event: .walletCreatedSuccessfully, params: params)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.goToNextStep()
                }

            case .failure(let error) where error.toTangemSdkError().isUserCancelled:
                // Do nothing
                break

            case .failure(let error):
                AppLogger.error(error: error)
                Analytics.logScanError(error, source: .onboarding, contextParams: getContextParams())
                alert = error.alertBinder
            }

            isMainButtonBusy = false
        }
    }
}
