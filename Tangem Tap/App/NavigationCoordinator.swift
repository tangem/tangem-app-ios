//
//  NavigationCoordinator.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class NavigationCoordinator: ObservableObject {
    // MARK: ReadView
    @Published var readToMain: Bool = false
    @Published var readToShop: Bool = false
    @Published var readToDisclaimer: Bool = false
    @Published var readToTwinOnboarding = false
    
    // MARK: DisclaimerView
    @Published var disclaimerToMain: Bool = false
    @Published var disclaimerToTwinOnboarding: Bool = false
    
    // MARK: SecurityManagementView
    @Published var securityToWarning: Bool = false
    
    // MARK: MainView
    @Published var mainToSettings = false
    @Published var mainToSend = false
    @Published var mainToSendChoise = false
    @Published var mainToCreatePayID = false
    @Published var mainToTopup = false
    @Published var mainToTwinOnboarding = false
    @Published var mainToTwinsWalletWarning = false
    @Published var mainToQR = false
    
    // MARK: SendView
    @Published var sendToQR = false
    
    // MARK: TwinCardOnboardingView
    @Published var twinOnboardingToTwinWalletCreation: Bool = false
    @Published var twinOnboardingToMain: Bool = false
    
    // MARK: DetailsView
    //All this stuff needed for fix permanent highlighting issues on ios 14
    @Published var detailsToTwinsRecreateWarning: Bool = false //for back 
}
