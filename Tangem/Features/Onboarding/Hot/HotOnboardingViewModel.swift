//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk
import TangemUIUtils
import TangemLocalization

final class HotOnboardingViewModel: ObservableObject {
    @Published var currentStep: HotOnboardingStep
    @Published var alert: AlertBinder?
    @Published var shouldFireConfetti: Bool = false
    @Published var canAcessCodeBack = false

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let progressBarHeight = OnboardingLayoutConstants.progressBarHeight
    let skipTitle = Localization.commonSkip

    lazy var createWalletViewModel = HotOnboardingCreateWalletViewModel(delegate: self)
    lazy var importCompletedViewModel = HotOnboardingSuccessViewModel(type: .import, delegate: self)
    lazy var seedPhraseIntroViewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: self)
    lazy var seedPhraseCompletedViewModel = HotOnboardingSuccessViewModel(type: .backup, delegate: self)
    lazy var checkAccessCodeViewModel = HotOnboardingCheckAccessCodeViewModel(delegate: self)
    lazy var accessCodeViewModel = HotOnboardingAccessCodeViewModel(delegate: self)
    lazy var doneViewModel = HotOnboardingSuccessViewModel(type: .done, delegate: self)

    lazy var importWalletViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        delegate: self
    )

    lazy var pushNotificationsViewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: pushNotificationsPermissionManager,
        delegate: self
    )

    var seedPhraseRecoveryViewModel: HotOnboardingSeedPhraseRecoveryViewModel?
    var seedPhraseUserValidationViewModel: OnboardingSeedPhraseUserValidationViewModel?

    var navigationBarTitle: String {
        switch currentStep {
        case .createWallet:
            ""
        case .importWallet:
            Localization.walletImportSeedNavtitle
        case .importCompleted:
            Localization.walletImportSuccessNavtitle
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted:
            Localization.commonBackup
        case .checkAccessCode:
            ""
        case .accessCode:
            Localization.accessCodeNavtitle
        case .pushNotifications:
            Localization.onboardingTitleNotifications
        case .done:
            Localization.commonDone
        }
    }

    var leadingButtonStyle: LeadingButtonStyle? {
        switch currentStep {
        case .createWallet, .importWallet:
            return .back
        case .importCompleted:
            return nil
        case .seedPhraseIntro:
            return .close
        case .seedPhraseRecovery, .seedPhraseUserValidation:
            return .back
        case .seedPhraseCompleted:
            return nil
        case .checkAccessCode:
            return .close
        case .accessCode:
            return canAcessCodeBack ? .back : nil
        case .pushNotifications, .done:
            return nil
        }
    }

    var trailingButtonStyle: TrailingButtonStyle? {
        switch currentStep {
        case .createWallet, .importWallet:
            return nil
        case .importCompleted:
            return nil
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted:
            return nil
        case .checkAccessCode:
            return nil
        case .accessCode:
            return .skip
        case .pushNotifications, .done:
            return nil
        }
    }

    var isProgressBarEnabled: Bool {
        switch currentStep {
        case .createWallet:
            false
        case .importWallet, .importCompleted:
            true
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted:
            true
        case .checkAccessCode:
            true
        case .accessCode:
            true
        case .pushNotifications, .done:
            true
        }
    }

    var currentProgress: CGFloat {
        let currentStepIndex = index(of: currentStep) ?? 0
        return CGFloat(currentStepIndex + 1) / CGFloat(input.steps.count)
    }

    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private lazy var pushNotificationsPermissionManager: PushNotificationsPermissionManager = {
        let factory = PushNotificationsHelpersFactory()
        return factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
    }()

    private let input: HotOnboardingInput
    private weak var coordinator: HotOnboardingRoutable?

    private var bag = Set<AnyCancellable>()

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator
        currentStep = input.steps.first ?? .createWallet
        bind()
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func backButtonAction() {
        switch currentStep {
        case .createWallet, .importWallet:
            closeHotOnboarding()
        case .importCompleted:
            break
        case .seedPhraseIntro, .seedPhraseCompleted:
            break
        case .seedPhraseRecovery:
            goToStep(.seedPhraseIntro)
        case .seedPhraseUserValidation:
            goToStep(.seedPhraseRecovery)
        case .checkAccessCode:
            break
        case .accessCode:
            accessCodeViewModel.resetState()
        case .pushNotifications, .done:
            break
        }
    }

    func onSkipTap() {
        switch currentStep {
        case .createWallet, .importWallet, .importCompleted:
            break
        case .seedPhraseIntro, .seedPhraseCompleted, .seedPhraseRecovery, .seedPhraseUserValidation:
            break
        case .checkAccessCode:
            break
        case .accessCode:
            onAccessCodeSkip()
        case .pushNotifications, .done:
            break
        }
    }

    func onCloseTap() {
        closeHotOnboarding()
    }
}

// MARK: - Steps navigation

private extension HotOnboardingViewModel {
    func goToStep(_ step: HotOnboardingStep) {
        currentStep = step
    }
}

// MARK: - Private methods

private extension HotOnboardingViewModel {
    func bind() {
        accessCodeViewModel.$state
            .map {
                switch $0 {
                case .accessCode:
                    false
                case .confirmAccessCode:
                    true
                }
            }
            .assign(to: &$canAcessCodeBack)
    }

    func index(of step: HotOnboardingStep) -> Int? {
        input.steps.firstIndex(of: step)
    }

    func goToNextStep() {
        guard
            let index = index(of: currentStep),
            index < input.steps.count - 1
        else {
            return
        }

        let step = input.steps[index + 1]
        goToStep(step)
    }

    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
    }

    func onAccessCodeSkip() {
        alert = AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .withPrimaryCancelButton(
                secondaryTitle: Localization.accessCodeAlertSkipOk,
                secondaryAction: { [weak self] in
                    // [REDACTED_TODO_COMMENT]
                    self?.goToNextStep()
                }
            )
        )
    }

    func closeHotOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingCreateWalletDelegate

extension HotOnboardingViewModel: HotOnboardingCreateWalletDelegate {
    func onCreateWallet() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - SeedPhraseImportDelegate

extension HotOnboardingViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?) {
        // [REDACTED_TODO_COMMENT]
        goToNextStep()
    }
}

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        let seedPhraseWords = getSeedPhraseWords()
        seedPhraseRecoveryViewModel = HotOnboardingSeedPhraseRecoveryViewModel(
            seedPhrase: .init(words: seedPhraseWords),
            delegate: self
        )
        goToNextStep()
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        let seedPhraseWords = getSeedPhraseWords()

        seedPhraseUserValidationViewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: seedPhraseWords[1],
            seventhWord: seedPhraseWords[6],
            eleventhWord: seedPhraseWords[10],
            createWalletAction: { [weak self] in
                self?.goToNextStep()
            }
        ))

        goToNextStep()
    }
}

// MARK: - HotOnboardingCheckAccessCodeDelegate

extension HotOnboardingViewModel: HotOnboardingCheckAccessCodeDelegate {
    func checkAccessCode(_ accessCode: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        accessCode == "111111"
    }

    func checkSuccessful() {
        goToNextStep()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingViewModel: HotOnboardingAccessCodeDelegate {
    func accessCodeComplete(accessCode: String) {
        // [REDACTED_TODO_COMMENT]
        goToNextStep()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goToNextStep()
    }
}

// MARK: - HotOnboardingSuccessDelegate

extension HotOnboardingViewModel: HotOnboardingSuccessDelegate {
    func fireConfetti() {
        shouldFireConfetti = true
    }

    func success() {
        switch currentStep {
        case .createWallet, .importWallet:
            break
        case .importCompleted:
            goToNextStep()
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation:
            break
        case .seedPhraseCompleted:
            goToNextStep()
        case .checkAccessCode, .accessCode, .pushNotifications:
            break
        case .done:
            closeHotOnboarding()
        }
    }
}

// MARK: - Types

extension HotOnboardingViewModel {
    enum LeadingButtonStyle {
        case back
        case close
    }

    enum TrailingButtonStyle {
        case skip
    }
}
