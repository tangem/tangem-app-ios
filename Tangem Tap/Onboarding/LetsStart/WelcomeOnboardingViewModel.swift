//
//  WelcomeOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class WelcomeOnboardingViewModel: ViewModel {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var imageLoaderService: CardImageLoaderService!
    weak var userPrefsService: UserPrefsService!
    
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var darkCardSettings: AnimatedViewSettings = .zero
    @Published var lightCardSettings: AnimatedViewSettings = .zero
    
    var shopURL: URL { Constants.shopURL }
    
    var currentStep: WelcomeStep {
        .welcome
    }
    
    private var bag: Set<AnyCancellable> = []
    private var cardImage: UIImage?
    
    private var container: CGSize = .zero
    
    var successCallback: (CardOnboardingInput) -> Void
    
    init(successCallback: @escaping (CardOnboardingInput) -> Void) {
        self.successCallback = successCallback
    }
    
    func setupContainer(_ size: CGSize) {
        let isInitialSetup = container == .zero
        container = size
        setupCards(animated: !isInitialSetup)
    }
    
    func scanCard() {
        guard userPrefsService.isTermsOfServiceAccepted else {
            showDisclaimer()
            return
        }
            
        isScanningCard = true
        cardsRepository.scan { [unowned self] result in
            switch result {
            case .success(let scanResult):
                guard let cardModel = scanResult.cardModel else {
                    break
                }
                
                processScannedCard(cardModel, isWithAnimation: true)
            case .failure(let error):
                print("Failed to scan card. Reason: \(error)")
                self.isScanningCard = false
            }
        }
    }
    
    func acceptDisclaimer() {
        userPrefsService.isTermsOfServiceAccepted = true
        navigation.onboardingToDisclaimer = false
    }
    
    func onboardingDismissed() {
        scanCard()
    }
    
    private func showDisclaimer() {
        navigation.onboardingToDisclaimer = true
    }
    
    private func processScannedCard(_ cardModel: CardViewModel, isWithAnimation: Bool) {
        stepsSetupService.stepsWithCardImage(for: cardModel)
            .sink { completion in
                if case let .failure(error) = completion {
                    self.error = error.alertBinder
                }
                self.isScanningCard = false
            } receiveValue: { [unowned self] (steps, image) in
                let input = CardOnboardingInput(steps: steps,
                                                cardModel: cardModel,
                                                cardImage: image,
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
