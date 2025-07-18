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
import TangemFoundation
import TangemUIUtils
import TangemLocalization

final class HotOnboardingViewModel: ObservableObject {
    @Published var currentStep: HotOnboardingStep
    @Published var alert: AlertBinder?
    @Published var shouldFireConfetti: Bool = false
    @Published var canAccessCodeCreateBack = false

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let progressBarHeight = OnboardingLayoutConstants.progressBarHeight
    let skipTitle = Localization.commonSkip

    lazy var createWalletViewModel = HotOnboardingCreateWalletViewModel(delegate: self)
    lazy var importCompletedViewModel = HotOnboardingSuccessViewModel(type: .walletImported, delegate: self)
    lazy var seedPhraseIntroViewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: self)
    lazy var seedPhraseRecoveryViewModel = HotOnboardingSeedPhraseRecoveryViewModel(delegate: self)
    lazy var seedPhraseRevealViewModel = HotOnboardingSeedPhraseRevealViewModel(delegate: self)
    lazy var seedPhaseBackupContinueViewModel = HotOnboardingSuccessViewModel(type: .seedPhaseBackupContinue, delegate: self)
    lazy var seedPhaseBackupFinishViewModel = HotOnboardingSuccessViewModel(type: .seedPhaseBackupFinish, delegate: self)
    lazy var accessCodeCreateViewModel = HotOnboardingAccessCodeViewModel(delegate: self)
    lazy var accessCodeValidateViewModel = HotOnboardingCheckAccessCodeViewModel(delegate: self)
    lazy var doneViewModel = HotOnboardingSuccessViewModel(type: .walletReady, delegate: self)

    lazy var importWalletViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        delegate: self
    )

    lazy var pushNotificationsViewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: pushNotificationsPermissionManager,
        delegate: self
    )

    var seedPhraseUserValidationViewModel: OnboardingSeedPhraseUserValidationViewModel?

    var navigationBarTitle: String {
        switch currentStep {
        case .createWallet, .accessCodeValidate:
            String.empty
        case .importSeedPhrase:
            Localization.walletImportSeedNavtitle
        case .importCompleted:
            Localization.walletImportSuccessNavtitle
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseValidate, .seedPhaseBackupContinue,
             .seedPhaseBackupFinish, .seedPhraseReveal:
            Localization.commonBackup
        case .accessCodeCreate:
            Localization.accessCodeNavtitle
        case .pushNotifications:
            Localization.onboardingTitleNotifications
        case .done:
            Localization.commonDone
        }
    }

    var leadingButtonStyle: LeadingButtonStyle? {
        let backAction = Action { [weak self] in
            self?.goToPreviousStep()
        }

        let closeAction = Action { [weak self] in
            self?.closeHotOnboarding()
        }

        switch currentStep {
        case .createWallet, .importSeedPhrase:
            return .back(closeAction)
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseValidate, .accessCodeValidate:
            return isStepFirst(currentStep) ? .close(closeAction) : .back(backAction)
        case .accessCodeCreate:
            return accessCodeCreateStepLeadingButtonStyle()
        case .seedPhraseReveal:
            return .close(closeAction)
        default:
            return nil
        }
    }

    var trailingButtonStyle: TrailingButtonStyle? {
        switch currentStep {
        case .accessCodeCreate:
            return accessCodeCreateStepTrailingButtonStyle()
        default:
            return nil
        }
    }

    var isProgressBarEnabled: Bool {
        switch input.flow {
        case .walletCreate, .accessCodeCreate, .accessCodeChange, .seedPhraseBackup, .seedPhraseReveal:
            false
        case .walletImport, .walletActivate:
            true
        }
    }

    var currentProgress: Double {
        let currentStepIndex = index(of: currentStep) ?? 0
        return Double(currentStepIndex + 1) / Double(steps.count)
    }

    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private lazy var pushNotificationsPermissionManager: PushNotificationsPermissionManager = {
        let factory = PushNotificationsHelpersFactory()
        return factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
    }()

    private let input: HotOnboardingInput
    private let steps: [HotOnboardingStep]
    private weak var coordinator: HotOnboardingRoutable?

    private var bag = Set<AnyCancellable>()

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator

        let steps = HotOnboardingStepsBuilder().buildSteps(flow: input.flow)
        self.steps = steps
        currentStep = steps.first ?? .createWallet

        bind()
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func onDismissalAttempt() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Steps navigation

private extension HotOnboardingViewModel {
    func goToNextStep() {
        guard
            let index = index(of: currentStep),
            index < steps.count - 1
        else {
            return
        }

        let step = steps[index + 1]
        goToStep(step)
    }

    func goToPreviousStep() {
        guard
            let index = index(of: currentStep),
            index > 0
        else {
            return
        }

        let step = steps[index - 1]
        goToStep(step)
    }

    func goToStep(_ step: HotOnboardingStep) {
        currentStep = step
    }

    func index(of step: HotOnboardingStep) -> Int? {
        steps.firstIndex(of: step)
    }

    func isStepFirst(_ step: HotOnboardingStep) -> Bool {
        steps.first == step
    }
}

// MARK: - Private methods

private extension HotOnboardingViewModel {
    func bind() {
        accessCodeCreateViewModel.$state
            .map {
                switch $0 {
                case .accessCode:
                    false
                case .confirmAccessCode:
                    true
                }
            }
            .assign(to: &$canAccessCodeCreateBack)
    }

    func accessCodeCreateStepLeadingButtonStyle() -> LeadingButtonStyle? {
        let backAction = Action { [weak accessCodeCreateViewModel] in
            accessCodeCreateViewModel?.resetState()
        }

        let closeAction = Action { [weak self] in
            self?.closeHotOnboarding()
        }

        if canAccessCodeCreateBack {
            return .back(backAction)
        } else {
            switch input.flow {
            case .accessCodeCreate, .accessCodeChange:
                return .close(closeAction)
            default:
                return nil
            }
        }
    }

    func accessCodeCreateStepTrailingButtonStyle() -> TrailingButtonStyle? {
        let skipAction = Action { [weak self] in
            self?.alert = self?.makeAccessCodeCreateSkipAlert()
        }

        switch input.flow {
        case .walletImport, .walletActivate:
            return .skip(skipAction)
        default:
            return nil
        }
    }

    func makeAccessCodeCreateSkipAlert() -> AlertBinder? {
        AlertBuilder.makeAlert(
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
        goToNextStep()
    }
}

// MARK: - HotOnboardingSeedPhraseRevealDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseRevealDelegate {
    func getSeedPhrase() -> [String] {
        getSeedPhraseWords()
    }

    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
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
    func validateAccessCode(_ accessCode: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        accessCode == "111111"
    }

    func validateSuccessful() {
        goToNextStep()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingViewModel: HotOnboardingAccessCodeDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        switch input.flow {
        case .walletImport, .walletActivate, .accessCodeCreate:
            true
        default:
            false
        }
    }

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
        case .importCompleted:
            goToNextStep()
        case .seedPhaseBackupContinue:
            goToNextStep()
        case .seedPhaseBackupFinish, .done:
            closeHotOnboarding()
        default:
            break
        }
    }
}

// MARK: - Types

extension HotOnboardingViewModel {
    enum LeadingButtonStyle {
        case back(Action)
        case close(Action)
    }

    enum TrailingButtonStyle {
        case skip(Action)
    }

    struct Action {
        let closure: () -> Void
    }
}
