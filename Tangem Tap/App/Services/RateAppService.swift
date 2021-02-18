//
//  RateAppService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import StoreKit

protocol RateAppChecker: class {
    var shouldShowRateAppWarning: Bool { get }
}

protocol RateAppController: class {
    func dismissRateAppWarning()
    func userReactToRateAppWarning(isPositive: Bool)
}

class RateAppService: RateAppChecker, RateAppController {
    
    private unowned var userPrefsService: UserPrefsService
    
    private(set) var shouldShowRateAppWarning: Bool = false
    
    init(userPrefsService: UserPrefsService) {
        self.userPrefsService = userPrefsService
        
        if userPrefsService.didUserRespondToRateApp {
            return
        }
        let numberOfLaunches = userPrefsService.numberOfLaunches

        guard let firstRateAppLaunchCounterPoint = userPrefsService.firstRateAppLaunchCounterPoint else {
            userPrefsService.firstRateAppLaunchCounterPoint = numberOfLaunches - 1
            return
        }

        guard let dismissAtLaunch = userPrefsService.dismissRateAppAtLaunch else {
            shouldShowRateAppWarning = (numberOfLaunches - firstRateAppLaunchCounterPoint) >= 3
            return
        }

        shouldShowRateAppWarning = (numberOfLaunches - dismissAtLaunch) >= 6
    }
    
    func dismissRateAppWarning() {
        userPrefsService.dismissRateAppAtLaunch = userPrefsService.numberOfLaunches
    }
    
    func userReactToRateAppWarning(isPositive: Bool) {
//        userPrefsService.didUserRespondToRateApp = true
        if isPositive {
            SKStoreReviewController.requestReview()
        }
    }
    
}
