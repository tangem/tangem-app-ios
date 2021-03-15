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
    var shouldCheckBalanceForRateApp: Bool { get }
    func registerPositiveBalanceDate()
    func dismissRateAppWarning()
    func userReactToRateAppWarning(isPositive: Bool)
}

class RateAppService: RateAppChecker, RateAppController {
    
    var shouldCheckBalanceForRateApp: Bool {
        !(userPrefsService.didUserRespondToRateApp ||
            userPrefsService.positiveBalanceAppearanceLaunch != nil)
    }
    
    private unowned var userPrefsService: UserPrefsService
    
    private(set) var shouldShowRateAppWarning: Bool = false
    
    private let positiveBalanceTimeThreshold: TimeInterval = 3600 * 24 * 3
    private let positiveBalanceLaunchThreshold: Int = 3
    
    init(userPrefsService: UserPrefsService) {
        self.userPrefsService = userPrefsService
        
        if userPrefsService.didUserRespondToRateApp {
            return
        }
        let numberOfLaunches = userPrefsService.numberOfLaunches

        guard
            let positiveBalanceDate = userPrefsService.positiveBalanceAppearanceDate,
            let positiveBalanceLaunch = userPrefsService.positiveBalanceAppearanceLaunch
        else { return }
        
        guard
            (Date().timeIntervalSince1970 - positiveBalanceDate.timeIntervalSince1970) > positiveBalanceTimeThreshold ||
            (numberOfLaunches - positiveBalanceLaunch) >= positiveBalanceLaunchThreshold
        else { return }
        
        guard let dismissAtLaunch = userPrefsService.dismissRateAppAtLaunch else {
            shouldShowRateAppWarning = true
            return
        }

        shouldShowRateAppWarning = (numberOfLaunches - dismissAtLaunch) >= 20
    }
    
    func dismissRateAppWarning() {
        userPrefsService.dismissRateAppAtLaunch = userPrefsService.numberOfLaunches
    }
    
    func userReactToRateAppWarning(isPositive: Bool) {
        userPrefsService.didUserRespondToRateApp = true
        if isPositive {
            SKStoreReviewController.requestReview()
        }
    }
    
    func registerPositiveBalanceDate() {
        guard userPrefsService.positiveBalanceAppearanceDate == nil else { return }
        
        userPrefsService.positiveBalanceAppearanceDate = Date()
        userPrefsService.positiveBalanceAppearanceLaunch = userPrefsService.numberOfLaunches
    }
    
}
