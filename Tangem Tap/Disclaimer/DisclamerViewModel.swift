//
//  DisclamerViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DisclaimerViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator! {
        didSet {
            navigation.objectWillChange
                          .receive(on: RunLoop.main)
                          .sink { [weak self] in
                              self?.objectWillChange.send()
                      }
                      .store(in: &bag)
        }
    }
    var assembly: Assembly!
    var userPrefsService: UserPrefsService!
    
    @Published var state: State = .accept
    
    private var bag = Set<AnyCancellable>()
    
    func accept() {
        userPrefsService.isTermsOfServiceAccepted = true
        navigation.openMainFromDisclaimer = true
    }
}

extension DisclaimerViewModel {
    enum State {
        case accept
        case read
    }
}
