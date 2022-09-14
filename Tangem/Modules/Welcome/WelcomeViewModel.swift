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
    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var discardAlert: ActionSheetBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    // This screen seats on the navigation stack permanently. We should preserve the navigationBar state to fix the random hide/disappear events of navigationBar on iOS13 on other screens down the navigation hierarchy.
    @Published var navigationBarHidden: Bool = false
    @Published var showingAuthentication = false

    var shouldShowAuthenticationView: Bool {
        AppSettings.shared.saveUserWallets && !userWalletListService.isEmpty && BiometricsUtil.isAvailable
    }

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

        scanCardInternal { [weak self] cardModel in
            self?.processScannedCard(cardModel, isWithAnimation: true)
        }
    }

    func unlockWithBiometry() {
        showingAuthentication = true
        userWalletListService.unlockWithBiometry(completion: self.didFinishUnlocking)
    }

    func unlockWithCard() {
        scanCardInternal { [weak self] cardModel in
            guard let self = self else { return }
            self.userWalletListService.unlockWithCard(cardModel.userWallet, completion: self.didFinishUnlocking)
        }
    }

    func tryAgain() {
        Analytics.log(.tryAgainTapped)
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.supportTapped)
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        openShop()
        Analytics.log(.getACard, params: [.source: Analytics.ParameterValue.welcome.rawValue])
    }

    func onAppear() {
        navigationBarHidden = true
        showInteruptedBackupAlertIfNeeded()
    }

    func onDissappear() {
        navigationBarHidden = false
    }

    private func scanCardInternal(_ completion: @escaping (CardViewModel) -> Void) {
        isScanningCard = true
        Analytics.log(.scanCardTapped)
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
                guard let self = self else { return }

                let numberOfFailedAttempts = self.failedCardScanTracker.numberOfFailedAttempts
                self.failedCardScanTracker.resetCounter()
                Analytics.log(numberOfFailedAttempts == 0 ? .firstScan : .secondScan)

                completion(cardModel)
            }

        subscription?.store(in: &bag)
    }

    private func processScannedCard(_ cardModel: CardViewModel, isWithAnimation: Bool) {
        let input = cardModel.onboardingInput
        self.isScanningCard = false

        if input.steps.needOnboarding {
            cardModel.userWalletModel?.updateAndReloadWalletModels(showProgressLoading: true)
            openOnboarding(with: input)
        } else {
            openMain(with: input)
        }
    }

    private func didFinishUnlocking(_ result: Result<Void, Error>) {
        if case .failure(let error) = result {
            print("Failed to unlock user wallets: \(error)")
            return
        }

        guard let model = userWalletListService.selectedModel else { return }
        coordinator.openMain(with: model)
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

    func openDisclaimer() {
        coordinator.openDisclaimer()
    }

    func openTokensList() {
        Analytics.log(.tokenListTapped)
        coordinator.openTokensList()
    }

    func openShop() {
        Analytics.log(.buyBottomTapped)
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

        let input = OnboardingInput(steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
                                    cardInput: .cardId(primaryCardId),
                                    welcomeStep: nil,
                                    twinData: nil,
                                    currentStepIndex: 0,
                                    isStandalone: true)

        self.openInterruptedBackup(with: input)
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
