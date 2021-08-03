//
//  OnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingViewModel: ViewModel {
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    
    unowned var cardsRepository: CardsRepository
    
    init(cardsRepository: CardsRepository) {
        self.cardsRepository = cardsRepository
    }
    
    var shopURL: URL { URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")! }

    func scanCard() {
        
    }
    
}
