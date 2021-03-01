//
//  UserPrefsService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class UserPrefsService {
	@Storage(type: StorageType.termsOfServiceAccepted, defaultValue: false)
    var isTermsOfServiceAccepted: Bool
	
	@Storage(type: StorageType.twinCardOnboardingDisplayed, defaultValue: false)
	var isTwinCardOnboardingWasDisplayed: Bool

	@Storage(type: StorageType.numberOfAppLaunches, defaultValue: 0)
	var numberOfLaunches: Int
    
    @Storage(type: StorageType.didUserRespondToRateApp, defaultValue: false)
    var didUserRespondToRateApp: Bool
    
    @Storage(type: StorageType.dismissRateAppAtLaunch, defaultValue: nil)
    var dismissRateAppAtLaunch: Int?
}
