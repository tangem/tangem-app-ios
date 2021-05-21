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
    @Published var readToTroubleshootingScan = false
    @Published var readToSendEmail: Bool = false
    
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
    @Published var mainToTokenDetails = false
    @Published var mainToAddTokens: Bool = false
    @Published var mainToTroubleshootingScan = false
    @Published var mainToWalletConnectQR: Bool = false
    
    // MARK: SendView
    @Published var sendToQR = false
    @Published var sendToSendEmail = false
    
    // MARK: TwinCardOnboardingView
    @Published var twinOnboardingToTwinWalletCreation: Bool = false
    @Published var twinOnboardingToMain: Bool = false
    
    // MARK: DetailsView
    //All this stuff needed for fix permanent highlighting issues on ios 14
    @Published var detailsToTwinsRecreateWarning: Bool = false //for back
    @Published var detailsToSendEmail: Bool = false
    @Published var detailsToManageTokens: Bool = false
    
    // MARK: Manage tokens
    @Published var manageTokensToAddNewTokens = false
    @Published var addNewTokensToCreateCustomToken = false
    
    // MARK: TokenDetailsView
    @Published var detailsToTopup = false
    @Published var detailsToSend = false
    
    // MARK: WalletConnectView
    @Published var walletConnectToQR = false

    func reset() {
        readToMain = false
        readToShop = false
        readToDisclaimer = false
        readToTwinOnboarding = false
        readToTroubleshootingScan = false
        readToSendEmail = false
        
        // MARK: DisclaimerView
        disclaimerToMain = false
        disclaimerToTwinOnboarding = false
        
        // MARK: SecurityManagementView
        securityToWarning = false
        
        // MARK: MainView
        mainToSettings = false
        mainToSend = false
        mainToSendChoise = false
        mainToCreatePayID = false
        mainToTopup = false
        mainToTwinOnboarding = false
        mainToTwinsWalletWarning = false
        mainToQR = false
        mainToTokenDetails = false
        mainToAddTokens = false
        mainToTroubleshootingScan = false
        mainToWalletConnectQR = false
        
        // MARK: SendView
        sendToQR = false
        sendToSendEmail = false
        
        // MARK: TwinCardOnboardingView
        twinOnboardingToTwinWalletCreation = false
        twinOnboardingToMain = false
        
        // MARK: DetailsView
        //All this stuff needed for fix permanent highlighting issues on ios 14
        detailsToTwinsRecreateWarning = false //for back
        detailsToSendEmail = false
        detailsToManageTokens = false
        
        // MARK: Manage tokens
        manageTokensToAddNewTokens = false
        addNewTokensToCreateCustomToken = false
        
        // MARK: TokenDetailsView
        detailsToTopup = false
        detailsToSend = false
        
        // MARK: WalletConnectView
        walletConnectToQR = false
    }
    
    deinit {
        print("NavigationCoordinator deinit")
    }
}
