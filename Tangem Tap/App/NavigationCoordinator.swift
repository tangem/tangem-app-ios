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
    @Published var readToMain: Bool = false {
        willSet {
            print("nav: readToMain: \(newValue)")
        }
    }
    @Published var readToShop: Bool = false {
        willSet {
            print("nav: readToShop: \(newValue)")
        }
    }
    @Published var readToDisclaimer: Bool = false {
        willSet {
            print("nav: readToDisclaimer: \(newValue)")
        }
    }
	@Published var readToTwinOnboarding = false {
        willSet {
            print("nav: readToTwinOnboarding: \(newValue)")
        }
    }
     
    // MARK: DisclaimerView
    @Published var disclaimerToMain: Bool = false {
        willSet {
            print("nav: disclaimerToMain: \(newValue)")
        }
    }
    
	@Published var disclaimerToTwinOnboarding: Bool = false {
        willSet {
            print("nav: disclaimerToTwinOnboarding: \(newValue)")
        }
    }
    
    // MARK: SecurityManagementView
    @Published var securityToWarning: Bool = false
    {
       willSet {
           print("nav: securityToWarning: \(newValue)")
       }
   }
    
    // MARK: MainView
    @Published var mainToSettings = false {
        willSet {
            print("nav: mainToSettings: \(newValue)")
        }
    }
    
    @Published var mainToSend = false {
        willSet {
            print("nav: mainToSend: \(newValue)")
        }
    }
    
    @Published var mainToSendChoise = false {
        willSet {
            print("nav: mainToSendChoise: \(newValue)")
        }
    }
    @Published var mainToCreatePayID = false {
        willSet {
            print("nav: mainToCreatePayID: \(newValue)")
        }
    }
    @Published var mainToTopup = false {
        willSet {
            print("nav: mainToTopup: \(newValue)")
        }
    }
    @Published var mainToTwinOnboarding = false {
        willSet {
            print("nav: mainToTwinOnboarding: \(newValue)")
        }
    }
    @Published var mainToTwinsWalletWarning = false {
        willSet {
            print("nav: mainToTwinsWalletWarning: \(newValue)")
        }
    }
    @Published var mainToQR = false {
        willSet {
            print("nav: mainToQR: \(newValue)")
        }
    }
    
    // MARK: SendView
    @Published var sendToQR = false {
        willSet {
            print("nav: sendToQR: \(newValue)")
        }
    }
	
	// MARK: TwinCardOnboardingView
	@Published var twinOnboardingToTwinWalletCreation: Bool = false  {
        willSet {
            print("nav: twinOnboardingToTwinWalletCreation: \(newValue)")
        }
    }
    @Published var twinOnboardingToMain: Bool = false {
        willSet {
            print("nav: twinOnboardingToMain: \(newValue)")
        }
    }
	
	// MARK: DetailsView
    //All this stuff needed for fix permanent highlighting issues on ios 14
    @Published var detailsToTwinsRecreateWarning: Bool = false //for back 
}
