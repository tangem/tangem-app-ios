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
    @Injected(\.onboardingStepsSetupService) private var stepsSetupService: OnboardingStepsSetupService
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var discardAlert: ActionSheetBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    private var storiesModelSubscription: AnyCancellable? = nil
    private var bag: Set<AnyCancellable> = []
    private var backupService: BackupService { backupServiceProvider.backupService }

    private unowned let coordinator: WelcomeRoutable

    init(coordinator: WelcomeRoutable) {
        self.coordinator = coordinator
        self.storiesModelSubscription = storiesModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] in
                self.objectWillChange.send()
            })
    }

    func scanCard() {
        guard AppSettings.shared.isTermsOfServiceAccepted else {
            openDisclaimer()
            return
        }

        isScanningCard = true

        var subscription: AnyCancellable? = nil

        subscription = cardsRepository.scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to scan card: \(error)")
                    self?.isScanningCard = false
                    self?.failedCardScanTracker.recordFailure()

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
                self?.processScannedCard(cardModel, isWithAnimation: true)
            }

        subscription?.store(in: &bag)
    }

    func requestSupport() {
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        openShop()
        Analytics.log(.getACard, params: [.source: .welcome])
    }

    func onAppear() {
        showInteruptedBackupAlertIfNeeded()
    }

    private func processScannedCard(_ cardModel: CardViewModel, isWithAnimation: Bool) {
        cardModel.cardInfo.primaryCard.map { backupService.setPrimaryCard($0) }

        stepsSetupService.steps(for: cardModel.cardInfo)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }
                self?.isScanningCard = false
            } receiveValue: { [unowned self] steps in
                let input = OnboardingInput(steps: steps,
                                            cardInput: .cardModel(cardModel),
                                            welcomeStep: nil,
                                            currentStepIndex: 0)

                self.isScanningCard = false
                if input.steps.needOnboarding {
                    cardModel.updateState()
                    openOnboarding(with: input)
                } else {
                    openMain(with: input)
                }

                self.bag.removeAll()
            }
            .store(in: &bag)
    }
}

// MARK: - Navigation
extension WelcomeViewModel {
    func openInterruptedBackup(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        coordinator.openMail(with: failedCardScanTracker)
    }

    func openDisclaimer() {
        coordinator.openDisclaimer()
    }

    func openTokensList() {
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
        if backupService.hasIncompletedBackup {
            let alert = Alert(title: Text("common_warning"),
                              message: Text("welcome_interrupted_backup_alert_message"),
                              primaryButton: .default(Text("welcome_interrupted_backup_alert_resume"), action: continueIncompletedBackup),
                              secondaryButton: .destructive(Text("welcome_interrupted_backup_alert_discard"), action: showExtraDiscardAlert))

            self.error = AlertBinder(alert: alert)
        }
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
        guard let primaryCardId = backupService.primaryCardId else {
            return
        }

        stepsSetupService.stepsForBackupResume()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    print("Failed to load image for new card")
                    self.error = error.alertBinder
                case .finished:
                    break
                }
            } receiveValue: { [weak self] steps in
                guard let self = self else { return }

                let input = OnboardingInput(steps: steps,
                                            cardInput: .cardId(primaryCardId),
                                            welcomeStep: nil,
                                            currentStepIndex: 0,
                                            isStandalone: true)

                self.openInterruptedBackup(with: input)
            }
            .store(in: &bag)
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
