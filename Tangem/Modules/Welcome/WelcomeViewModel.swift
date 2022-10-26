//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class WelcomeViewModel: ObservableObject {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.saletPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var discardAlert: ActionSheetBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    // This screen seats on the navigation stack permanently. We should preserve the navigationBar state to fix the random hide/disappear events of navigationBar on iOS13 on other screens down the navigation hierarchy.
    @Published var navigationBarHidden: Bool = false

    private var storiesModelSubscription: AnyCancellable? = nil
    private var bag: Set<AnyCancellable> = []
    private var backupService: BackupService { backupServiceProvider.backupService }

    private unowned let coordinator: WelcomeRoutable

    private var hasInterruptedSaltPayBackup: Bool {
        guard backupService.hasIncompletedBackup,
              let primaryCard = backupService.primaryCard,
              let batchId = primaryCard.batchId else {
            return false
        }

        return SaltPayUtil().isSaltPayCard(batchId: batchId, cardId: primaryCard.cardId)
    }

    init(coordinator: WelcomeRoutable) {
        self.coordinator = coordinator
        cardsRepository.delegate = self
        self.storiesModelSubscription = storiesModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            })
    }

    func scanCard() {
        isScanningCard = true
        Analytics.log(.buttonScanCard)
        var subscription: AnyCancellable? = nil

        subscription = cardsRepository.scanPublisher()
            .flatMap { [weak self] response -> AnyPublisher<CardViewModel, Error> in
                let saltPayUtil = SaltPayUtil()
                let hasSaltPayBackup = self?.hasInterruptedSaltPayBackup ?? false
                let primaryCardId = self?.backupService.primaryCard?.cardId ?? ""

                if hasSaltPayBackup && response.cardId != primaryCardId  {
                    return .anyFail(error: SaltPayRegistratorError.emptyBackupCardScanned)
                }

                if saltPayUtil.isBackupCard(cardId: response.cardId) {
                    if let backupInput = response.backupInput, backupInput.steps.stepsCount > 0 {
                        return .anyFail(error: SaltPayRegistratorError.emptyBackupCardScanned)
                    } else {
                        return .justWithError(output: response)
                    }
                }

                guard let saltPayRegistrator = self?.saltPayRegistratorProvider.registrator else {
                    return .justWithError(output: response)
                }

                return saltPayRegistrator.updatePublisher()
                    .map { _ in
                        return response
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to scan card: \(error)")
                    self?.isScanningCard = false
                    self?.failedCardScanTracker.recordFailure()

                    if let salpayError = error as? SaltPayRegistratorError {
                        self?.error = salpayError.alertBinder
                        return
                    }

                    if self?.failedCardScanTracker.shouldDisplayAlert ?? false {
                        self?.showTroubleshootingView = true
                    } else {
                        switch error.toTangemSdkError() {
                        case .unknownError, .cardVerificationFailed:
                            self?.error = error.alertBinder
                        default:
                            break
                        }
                    }
                }
                subscription.map { _ = self?.bag.remove($0) }
            } receiveValue: { [weak self] cardModel in
                self?.failedCardScanTracker.resetCounter()
                Analytics.log(.cardWasScanned)
                DispatchQueue.main.async {
                    self?.processScannedCard(cardModel, isWithAnimation: true)
                }
            }

        subscription?.store(in: &bag)
    }

    func tryAgain() {
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        openShop()
        Analytics.log(.getACard, params: [.source: Analytics.ParameterValue.welcome.rawValue])
        Analytics.log(.buttonBuyCards)
    }

    func onAppear() {
        navigationBarHidden = true
        Analytics.log(.introductionProcessOpened)
        showInteruptedBackupAlertIfNeeded()
    }

    func onDissappear() {
        navigationBarHidden = false
    }

    private func processScannedCard(_ cardModel: CardViewModel, isWithAnimation: Bool) {
        let input = cardModel.onboardingInput
        self.isScanningCard = false

        if input.steps.needOnboarding {
            cardModel.userWalletModel?.updateAndReloadWalletModels()
            openOnboarding(with: input)
        } else {
            openMain(with: input)
        }
    }
}

// MARK: - Navigation
extension WelcomeViewModel {
    func openInterruptedBackup(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        coordinator.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openTokensList() {
        Analytics.log(.buttonTokensList)
        coordinator.openTokensList()
    }

    func openShop() {
        coordinator.openShop()
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboarding(with: input)
    }

    func openMain(with input: OnboardingInput) {
        if let card = input.cardInput.cardModel {
            coordinator.openMain(with: card)
        }
    }
}

// MARK: - Resume interrupted backup
private extension WelcomeViewModel {
    func showInteruptedBackupAlertIfNeeded() {
        guard backupService.hasIncompletedBackup, !hasInterruptedSaltPayBackup else { return }

        let alert = Alert(title: Text("common_warning"),
                          message: Text("welcome_interrupted_backup_alert_message"),
                          primaryButton: .default(Text("welcome_interrupted_backup_alert_resume"), action: continueIncompletedBackup),
                          secondaryButton: .destructive(Text("welcome_interrupted_backup_alert_discard"), action: showExtraDiscardAlert))

        self.error = AlertBinder(alert: alert)
    }

    func showExtraDiscardAlert() {
        let buttonResume: ActionSheet.Button = .cancel(Text("welcome_interrupted_backup_discard_resume"), action: continueIncompletedBackup)
        let buttonDiscard: ActionSheet.Button = .destructive(Text("welcome_interrupted_backup_discard_discard"), action: backupService.discardIncompletedBackup)
        let sheet = ActionSheet(title: Text("welcome_interrupted_backup_discard_title"),
                                message: Text("welcome_interrupted_backup_discard_message"),
                                buttons: [buttonDiscard, buttonResume])

        DispatchQueue.main.async {
            self.discardAlert = ActionSheetBinder(sheet: sheet)
        }
    }

    func continueIncompletedBackup() {
        guard let primaryCardId = backupService.primaryCard?.cardId else {
            return
        }

        let input = OnboardingInput(steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
                                    cardInput: .cardId(primaryCardId),
                                    welcomeStep: nil,
                                    twinData: nil,
                                    currentStepIndex: 0,
                                    isStandalone: true)

        self.openInterruptedBackup(with: input)
    }
}

extension WelcomeViewModel: CardsRepositoryDelegate {
    func showTOS(at url: URL, _ completion: @escaping (Bool) -> Void) {
        coordinator.openDisclaimer(at: url, completion)
    }
}

extension WelcomeViewModel: WelcomeViewLifecycleListener {
    func resignActve() {
        storiesModel.resignActve()
    }

    func becomeActive() {
        storiesModel.becomeActive()
    }
}
