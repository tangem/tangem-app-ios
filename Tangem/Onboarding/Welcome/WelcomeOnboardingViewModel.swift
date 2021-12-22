//
//  WelcomeOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class WelcomeOnboardingViewModel: ViewModel, ObservableObject {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var userPrefsService: UserPrefsService!
    weak var backupService: BackupService!
    weak var failedCardScanTracker: FailedCardScanTracker!
    
    @Published var isScanningCard: Bool = false
    @Published var isBackupModal: Bool = false
    @Published var error: AlertBinder?
    @Published var discardAlert: ActionSheetBinder?
    @Published var darkCardSettings: AnimatedViewSettings = .zero
    @Published var lightCardSettings: AnimatedViewSettings = .zero
    
    var currentStep: WelcomeStep {
        .welcome
    }
    
    private var bag: Set<AnyCancellable> = []
    private var cardImage: UIImage?
    
    private var container: CGSize = .zero
    
    var successCallback: (OnboardingInput) -> Void
    
    init(successCallback: @escaping (OnboardingInput) -> Void) {
        self.successCallback = successCallback
    }
    
    func setupContainer(_ size: CGSize) {
        let isInitialSetup = container == .zero
        container = size
        setupCards(animated: !isInitialSetup)
    }
    
    func reset() {
        setupCards(animated: false)
    }
    
    func scanCard() {
        guard userPrefsService.isTermsOfServiceAccepted else {
            showDisclaimer()
            return
        }
            
        isScanningCard = true
        
        var subscription: AnyCancellable? = nil
        
        subscription = cardsRepository.scanPublisher()
            .receive(on: DispatchQueue.main)
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to scan card: \(error)")
                    self?.isScanningCard = false
                    self?.failedCardScanTracker.recordFailure()
                    
                    if self?.failedCardScanTracker.shouldDisplayAlert ?? false {
                        self?.navigation.readToTroubleshootingScan = true
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
            } receiveValue: { [weak self] (result, _) in
                self?.failedCardScanTracker.resetCounter()
                
                guard let cardModel = result.cardModel else {
                    return
                }
                
                self?.processScannedCard(cardModel, isWithAnimation: true)
            }
        
        subscription?.store(in: &bag)
    }
    
    func acceptDisclaimer() {
        userPrefsService.isTermsOfServiceAccepted = true
        navigation.onboardingToDisclaimer = false
    }
    
    func disclaimerDismissed() {
        scanCard()
    }
    
    func onAppear() {
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
                                            cardsPosition: nil,
                                            welcomeStep: nil,
                                            currentStepIndex: 0,
                                            successCallback: { [weak self] in
                                                self?.navigation.welcomeToBackup = false
                                            },
                                            isStandalone: false)
                self.assembly.makeCardOnboardingViewModel(with: input)
                self.navigation.welcomeToBackup = true
            }
            .store(in: &bag)
    }
    
    private func showDisclaimer() {
        navigation.onboardingToDisclaimer = true
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
                                            cardsPosition: (darkCardSettings, lightCardSettings),
                                            welcomeStep: .welcome,
                                            currentStepIndex: 0,
                                            successCallback: nil)
                
                self.isScanningCard = false
                self.successCallback(input)
                self.bag.removeAll()
            }
            .store(in: &bag)
    }
    
    private func setupCards(animated: Bool) {
        darkCardSettings = WelcomeCardLayout.main.cardSettings(at: currentStep, in: container, animated: animated)
        lightCardSettings = WelcomeCardLayout.supplementary.cardSettings(at: currentStep, in: container, animated: animated)
    }
    
}
