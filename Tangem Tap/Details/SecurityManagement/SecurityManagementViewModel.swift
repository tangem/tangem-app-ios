//
//  SecurityManagementViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SecurityManagementViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator!{
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
    var bag = Set<AnyCancellable>()
    @Published var cardViewModel: CardViewModel! {
        didSet {
            selectedOption = cardViewModel.currentSecOption
            cardViewModel.objectWillChange
                          .receive(on: RunLoop.main)
                          .sink { [weak self] in
                              self?.objectWillChange.send()
                      }
                      .store(in: &bag)
        }
    }
    
    var cardsRepository: CardsRepository!
    
    @Published var error: AlertBinder?
    @Published var selectedOption: SecurityManagementOption = .longTap
    @Published var isLoading: Bool = false
    
    var actionButtonPressedHandler: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void {
        return { completion in
            self.cardsRepository.changeSecOption(self.selectedOption,
                                                 card: self.cardViewModel.card,
                                                 completion: completion) }
    }
    
    func onTap() {
        switch selectedOption {
        case .accessCode, .passCode:
            navigation.openWarning = true
        case .longTap:
            isLoading = true
            cardsRepository.changeSecOption(.longTap,
                                            card: self.cardViewModel.card) { result in
                self.isLoading = false
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    self.error = error.alertBinder
                }
            }
        }
    }
}


enum SecurityManagementOption: CaseIterable, Identifiable {
    case longTap
    case passCode
    case accessCode
    
    var id: String { "\(self)" }
    
    var title: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code".localized
        case .longTap:
            return "details_manage_security_long_tap".localized
        case .passCode:
            return "details_manage_security_passcode".localized
        }
    }
    
    var subtitle: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code_description".localized
        case .longTap:
            return "details_manage_security_long_tap_description".localized
        case .passCode:
            return "details_manage_security_passcode_description".localized
        }
    }
}
