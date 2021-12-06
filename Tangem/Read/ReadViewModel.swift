////
////  ReadViewModel.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//import TangemSdk
//import Combine
//
//class ReadViewModel: ViewModel {
//    weak var navigation: NavigationCoordinator!
//    weak var assembly: Assembly!
//    
//    //injected
//    weak var cardsRepository: CardsRepository!
//    weak var userPrefsService: UserPrefsService!
//    
//    weak var failedCardScanTracker: FailedCardScanTracker!
//    
//    //viewState
//    [REDACTED_USERNAME] var state: State = .welcome
//    //scan button state
//    [REDACTED_USERNAME] var isLoading: Bool = false
//    [REDACTED_USERNAME] var scanError: AlertBinder?
//    var shopURL = URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")!
//    
//    [REDACTED_USERNAME](type: StorageType.firstTimeScan, defaultValue: true)
//    private var firstTimeScan: Bool
//    
//    private var bag = Set<AnyCancellable>()
//    init() {
//        self.state = firstTimeScan ? .welcome : .welcomeBack
//    }
//    
//    func nextState() {
//        switch state {
//        case .read, .welcomeBack:
//            break
//        case .ready:
//            state = .read
//        case .welcome:
//            state = .ready
//        }
//    }
//    
//    func scan() {
//        self.isLoading = true
//        cardsRepository.scan { [weak self] scanResult in
//            guard let self = self else { return }
//            
//            defer { self.isLoading = false }
//            switch scanResult {
//            case .success(let result):
//                self.failedCardScanTracker.resetCounter()
//                defer {
//                    self.firstTimeScan = false
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        self.state = .welcomeBack
//                    }
//                }
//                
//                guard self.userPrefsService.isTermsOfServiceAccepted else {
//                    self.navigation.readToDisclaimer = true
//                    break
//                }
//                
//                guard result.card?.isTwinCard ?? false,
//                      !self.userPrefsService.isTwinCardOnboardingWasDisplayed else {
//                    self.navigation.readToMain = true
//                    break
//                }
//                
//                self.navigation.readToTwinOnboarding = true
//                
//            case .failure(let error):
//                self.failedCardScanTracker.recordFailure()
//                
//                if self.failedCardScanTracker.shouldDisplayAlert {
//                    self.navigation.readToTroubleshootingScan = true
//                } else {
//                    switch error.toTangemSdkError() {
//                    case .unknownError, .cardVerificationFailed:
//                        self.scanError = error.alertBinder
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//    }
//}
//
//extension ReadViewModel {
//    enum State {
//        case welcome
//        case welcomeBack
//        case ready
//        case read
//    }
//}
