//
//  LetsStartOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class LetsStartOnboardingViewModel: ViewModel {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var imageLoaderService: CardImageLoaderService!
    
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    
    var shopURL: URL { Constants.shopURL }
    
    private var bag: Set<AnyCancellable> = []
    private var cardImage: UIImage?
    
    var successCallback: (CardOnboardingInput) -> Void
    
    init(successCallback: @escaping (CardOnboardingInput) -> Void) {
        self.successCallback = successCallback
    }
    
    func scanCard() {
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
                                                currentStepIndex: 0,
                                                cardImage: image,
                                                successCallback: nil)
                
                self.isScanningCard = false
                self.successCallback(input)
                self.bag.removeAll()
            }
            .store(in: &bag)

    }
    
}
