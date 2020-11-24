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
    @Published var openMain: Bool = false
    @Published var openShop: Bool = false
    @Published var openDisclaimer: Bool = false
    
    // MARK: DisclaimerView
    @Published var openMainFromDisclaimer: Bool = false
	@Published var openTwinCardOnboarding: Bool = false
    
    // MARK: SecurityManagementView
    @Published var openWarning: Bool = false
    
    // MARK: MainView
    @Published var showSettings = false
    @Published var showSend = false
    @Published var showSendChoise = false
    @Published var showCreatePayID = false
    @Published var showTopup = false
	@Published var showTwinCardOnboarding = false
	@Published var showTwinsWalletCreation = false
    
    // MARK: SendView
    @Published var showQR = false
	
	// MARK: TwinCardOnboardingView
	@Published var onboardingOpenMain: Bool = false
	@Published var onboardingOpenTwinCardWalletCreation: Bool = false
	
	// MARK: DetailsView
	@Published var detailsShowTwinsRecreateWarning: Bool = false {
		willSet {
			print("Navigation values setting new value on details show twins recreate warning", newValue)
		}
		didSet {
			print("Navigation values new value on details show twins recreate warning was set", detailsShowTwinsRecreateWarning)
		}
	}
	
	func printValues() {
		print("----------Navigation values--------------")
		withUnsafePointer(to: self) {
			print("App navigation value \(self) has address: \(String(format: "%p", $0))")
		}
		print("Onboarding open twin card wallet creation:", onboardingOpenTwinCardWalletCreation)
		print("Details show twins recreate warning:", detailsShowTwinsRecreateWarning)
		print("------------------------\n")
	}
}
