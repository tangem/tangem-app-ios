//
//  DisclamerViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DisclaimerViewModel: ViewModel {
    var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var userPrefsService: UserPrefsService!
    
    var state: State = .accept
	
	var isTwinCard: Bool
    
    private var bag = Set<AnyCancellable>()
    
	init(isTwinCard: Bool) {
		self.isTwinCard = isTwinCard
	}
	
    func accept() {
        userPrefsService.isTermsOfServiceAccepted = true
		if isTwinCard, !userPrefsService.isTwinCardOnboardingWasDisplayed {
			navigation.openTwinCardOnboarding = true
		} else {
			navigation.openMainFromDisclaimer = true
		}
    }
}

extension DisclaimerViewModel {
    enum State {
        case accept
        case read
    }
}
