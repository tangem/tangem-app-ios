//
//  ReadViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

class ReadViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator!
    var assembly: Assembly!
    
    //injected
    var cardsRepository: CardsRepository!
    var userPrefsService: UserPrefsService!
    
    //viewState
    @Published var state: State = .welcome
    //scan button state
    @Published var isLoading: Bool = false
    @Published var scanError: AlertBinder?
    
    @Storage("tangem_tap_first_time_scan", defaultValue: true)
    private var firstTimeScan: Bool
    
    init() {
        self.state = firstTimeScan ? .welcome : .welcomeBack
    }
    
    func openShop() {
        UIApplication.shared.open(URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")!, options: [:], completionHandler: nil)
    }
    
    func nextState() {
        switch state {
        case .read, .welcomeBack:
            break
        case .ready:
            state = .read
        case .welcome:
            state = .ready
        }
    }
    
    func scan() {
        self.isLoading = true
        cardsRepository.scan { [weak self] scanResult in
            guard let self = self else { return }
            switch scanResult {
            case .success:
                if self.userPrefsService.isTermsOfServiceAccepted {
                    self.navigation.openMain = true
                } else {
                    self.navigation.openDisclaimer = true
                }
                self.firstTimeScan = false
            case .failure(let error):
                if case .unknownError = error.toTangemSdkError() {
                    self.scanError = error.alertBinder
                }
            }
             self.isLoading = false
        }
    }
}

extension ReadViewModel {
    enum State {
        case welcome
        case welcomeBack
        case ready
        case read
    }
}
