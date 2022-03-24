//
//  NavigationCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class NavigationCoordinator: ObservableObject {
    // MARK: ReadView
    @Published var readToMain: Bool = false {
        didSet {
            print("Did set read to main: \(readToMain)")
        }
    }
    @Published var readToShop: Bool = false
    @Published var readToTokenList: Bool = false
    @Published var readToDisclaimer: Bool = false
    @Published var readToTwinOnboarding = false
    @Published var readToTroubleshootingScan = false
    @Published var readToSendEmail: Bool = false
    
    @Published var welcomeToBackup: Bool = false
    
    @Published var onboardingToDisclaimer: Bool = false
    @Published var onboardingToBuyCrypto: Bool = false
    @Published var onboardingToQrTopup: Bool = false
    @Published var onboardingWalletToAccessCode: Bool = false
    
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
    @Published var mainToBuyCrypto = false
    @Published var mainToQR = false
    @Published var mainToTokenDetails = false
    @Published var mainToAddTokens: Bool = false
    @Published var mainToTroubleshootingScan = false
    @Published var mainToWalletConnectQR: Bool = false
    @Published var mainToTradeSheet: Bool = false
    @Published var mainToSellCrypto: Bool = false
    @Published var mainToCardOnboarding: Bool = false 
    
    // MARK: SendView
    @Published var sendToQR = false
    @Published var sendToSendEmail = false
    
    // MARK: PushView
    @Published var pushToSendEmail = false
    
    // MARK: TwinCardOnboardingView
    @Published var twinOnboardingToTwinWalletCreation: Bool = false
    @Published var twinOnboardingToMain: Bool = false
    
    // MARK: DetailsView
    //All this stuff needed for fix permanent highlighting issues on ios 14
    @Published var detailsToTwinsRecreateWarning: Bool = false //for back
    @Published var detailsToSendEmail: Bool = false
    @Published var detailsToManageTokens: Bool = false
    @Published var detailsToBackup: Bool = false //for back
    
    // MARK: Manage tokens
    @Published var manageTokensToAddNewTokens = false
    @Published var addNewTokensToCreateCustomToken = false
    
    // MARK: TokenDetailsView
    @Published var detailsToBuyCrypto = false
    @Published var detailsToSend = false
    @Published var detailsToSellCrypto = false
    @Published var detailsToTradeSheet: Bool = false
    
    // MARK: WalletConnectView
    @Published var walletConnectToQR = false
    
    @Published var onboardingReset = false

    func popToRoot() {
        readToMain = false
        readToDisclaimer = false
        readToShop = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.reset()
        }
    }
    
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
        mainToBuyCrypto = false
        mainToQR = false
        mainToTokenDetails = false
        mainToAddTokens = false
        mainToTroubleshootingScan = false
        mainToWalletConnectQR = false
        mainToTradeSheet = false
        mainToSellCrypto = false
        
        // MARK: SendView
        sendToQR = false
        sendToSendEmail = false
        
        // MARK: PushView
        pushToSendEmail = false
        
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
        detailsToBuyCrypto = false
        detailsToSend = false
        detailsToSellCrypto = false
        
        // MARK: WalletConnectView
        walletConnectToQR = false
    }
    
    deinit {
        print("NavigationCoordinator deinit")
    }
}
