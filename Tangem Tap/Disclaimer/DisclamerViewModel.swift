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
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var userPrefsService: UserPrefsService!
    
    var state: State = .accept
	var isTwinCard: Bool = false
    
    private var bag = Set<AnyCancellable>()
	
    func accept() {
        userPrefsService.isTermsOfServiceAccepted = true
		if isTwinCard, !userPrefsService.isTwinCardOnboardingWasDisplayed {
			navigation.disclaimerToTwinOnboarding = true
		} else {
			navigation.disclaimerToMain = true
		}
    }
}

extension DisclaimerViewModel {
    enum State {
        case accept
        case read
    }
}
